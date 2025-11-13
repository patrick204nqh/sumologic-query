# frozen_string_literal: true

require 'net/http'
require 'json'
require 'uri'
require 'base64'

module Sumologic
  # Lightweight Sumo Logic Search Job API client
  # Handles historical log queries with automatic polling and pagination
  class Client
    API_VERSION = 'v1'
    DEFAULT_POLL_INTERVAL = 20 # seconds
    DEFAULT_TIMEOUT = 300 # seconds (5 minutes)
    MAX_MESSAGES_PER_REQUEST = 10_000

    attr_reader :access_id, :access_key, :deployment, :base_url

    def initialize(access_id: nil, access_key: nil, deployment: nil)
      @access_id = access_id || ENV.fetch('SUMO_ACCESS_ID', nil)
      @access_key = access_key || ENV.fetch('SUMO_ACCESS_KEY', nil)
      @deployment = deployment || ENV['SUMO_DEPLOYMENT'] || 'us2'
      @base_url = deployment_url(@deployment)

      validate_credentials!
    end

    # Main search method
    # Returns array of messages/records as JSON
    def search(query:, from_time:, to_time:, time_zone: 'UTC', limit: nil)
      job_id = create_job(query, from_time, to_time, time_zone)
      poll_until_complete(job_id)
      messages = fetch_all_messages(job_id, limit)
      delete_job(job_id)
      messages
    rescue StandardError => e
      delete_job(job_id) if job_id
      raise Error, "Search failed: #{e.message}"
    end

    private

    def validate_credentials!
      raise AuthenticationError, 'SUMO_ACCESS_ID not set' unless @access_id
      raise AuthenticationError, 'SUMO_ACCESS_KEY not set' unless @access_key
    end

    def deployment_url(deployment)
      case deployment
      when /^http/
        deployment # Full URL provided
      when 'us1'
        'https://api.sumologic.com/api/v1'
      when 'us2'
        'https://api.us2.sumologic.com/api/v1'
      when 'eu'
        'https://api.eu.sumologic.com/api/v1'
      when 'au'
        'https://api.au.sumologic.com/api/v1'
      else
        "https://api.#{deployment}.sumologic.com/api/v1"
      end
    end

    def auth_header
      encoded = Base64.strict_encode64("#{@access_id}:#{@access_key}")
      "Basic #{encoded}"
    end

    def create_job(query, from_time, to_time, time_zone)
      uri = URI("#{@base_url}/search/jobs")
      request = Net::HTTP::Post.new(uri)
      request['Authorization'] = auth_header
      request['Content-Type'] = 'application/json'
      request['Accept'] = 'application/json'

      body = {
        query: query,
        from: from_time,
        to: to_time,
        timeZone: time_zone
      }
      request.body = body.to_json

      response = http_request(uri, request)
      data = JSON.parse(response.body)

      raise Error, "Failed to create job: #{data['message']}" unless data['id']

      log_info "Created search job: #{data['id']}"
      data['id']
    end

    def poll_until_complete(job_id, timeout: DEFAULT_TIMEOUT)
      uri = URI("#{@base_url}/search/jobs/#{job_id}")
      start_time = Time.now
      interval = DEFAULT_POLL_INTERVAL

      loop do
        raise TimeoutError, "Search job timed out after #{timeout} seconds" if Time.now - start_time > timeout

        request = Net::HTTP::Get.new(uri)
        request['Authorization'] = auth_header
        request['Accept'] = 'application/json'

        response = http_request(uri, request)
        data = JSON.parse(response.body)

        state = data['state']
        log_info "Job state: #{state} (#{data['messageCount']} messages, #{data['recordCount']} records)"

        case state
        when 'DONE GATHERING RESULTS'
          return data
        when 'CANCELLED', 'FORCE PAUSED'
          raise Error, "Search job #{state.downcase}"
        end

        sleep interval
      end
    end

    def fetch_all_messages(job_id, limit = nil)
      messages = []
      offset = 0
      total_fetched = 0

      loop do
        batch_limit = if limit
                        [MAX_MESSAGES_PER_REQUEST, limit - total_fetched].min
                      else
                        MAX_MESSAGES_PER_REQUEST
                      end

        break if batch_limit <= 0

        uri = URI("#{@base_url}/search/jobs/#{job_id}/messages")
        uri.query = URI.encode_www_form(offset: offset, limit: batch_limit)

        request = Net::HTTP::Get.new(uri)
        request['Authorization'] = auth_header
        request['Accept'] = 'application/json'

        response = http_request(uri, request)
        data = JSON.parse(response.body)

        batch = data['messages'] || []
        messages.concat(batch)
        total_fetched += batch.size

        log_info "Fetched #{batch.size} messages (total: #{total_fetched})"

        break if batch.size < batch_limit # No more messages
        break if limit && total_fetched >= limit

        offset += batch.size
      end

      messages
    end

    def delete_job(job_id)
      return unless job_id

      uri = URI("#{@base_url}/search/jobs/#{job_id}")
      request = Net::HTTP::Delete.new(uri)
      request['Authorization'] = auth_header

      http_request(uri, request)
      log_info "Deleted search job: #{job_id}"
    rescue StandardError => e
      log_error "Failed to delete job #{job_id}: #{e.message}"
    end

    def http_request(uri, request)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.read_timeout = 60
      http.open_timeout = 10

      response = http.request(request)

      case response.code.to_i
      when 200..299
        response
      when 401, 403
        raise AuthenticationError, "Authentication failed: #{response.body}"
      when 429
        raise Error, "Rate limit exceeded: #{response.body}"
      else
        raise Error, "HTTP #{response.code}: #{response.body}"
      end
    end

    def log_info(message)
      warn "[Sumologic::Client] #{message}" if ENV['SUMO_DEBUG'] || $DEBUG
    end

    def log_error(message)
      warn "[Sumologic::Client ERROR] #{message}"
    end
  end
end
