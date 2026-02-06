# frozen_string_literal: true

module Sumologic
  # Centralized configuration for Sumo Logic client
  class Configuration
    attr_accessor :access_id, :access_key, :deployment, :timeout, :initial_poll_interval, :max_poll_interval,
                  :poll_backoff_factor, :max_messages_per_request, :max_workers, :request_delay,
                  :connect_timeout, :read_timeout, :max_retries, :retry_base_delay, :retry_max_delay

    API_VERSION = 'v1'

    def initialize
      # Authentication
      @access_id = ENV.fetch('SUMO_ACCESS_ID', nil)
      @access_key = ENV.fetch('SUMO_ACCESS_KEY', nil)
      @deployment = ENV['SUMO_DEPLOYMENT'] || 'us2'

      # Search job polling
      @initial_poll_interval = 2 # seconds - aggressive polling for faster response
      @max_poll_interval = 15 # seconds - slow down for large queries
      @poll_backoff_factor = 1.5 # increase interval by 50% each time

      # Timeouts and limits
      @timeout = 300 # seconds (5 minutes) - overall operation timeout
      @connect_timeout = ENV.fetch('SUMO_CONNECT_TIMEOUT', '10').to_i # seconds
      @read_timeout = ENV.fetch('SUMO_READ_TIMEOUT', '60').to_i # seconds
      @max_messages_per_request = 10_000

      # Retry configuration
      @max_retries = ENV.fetch('SUMO_MAX_RETRIES', '3').to_i
      @retry_base_delay = ENV.fetch('SUMO_RETRY_BASE_DELAY', '1.0').to_f # seconds
      @retry_max_delay = ENV.fetch('SUMO_RETRY_MAX_DELAY', '30.0').to_f # seconds

      # Rate limiting (default: 5 workers, 250ms delay)
      @max_workers = ENV.fetch('SUMO_MAX_WORKERS', '5').to_i
      @request_delay = ENV.fetch('SUMO_REQUEST_DELAY', '0.25').to_f
    end

    def base_url
      @base_url ||= build_base_url
    end

    def validate!
      raise AuthenticationError, 'SUMO_ACCESS_ID not set' unless @access_id
      raise AuthenticationError, 'SUMO_ACCESS_KEY not set' unless @access_key
    end

    private

    def build_base_url
      case @deployment
      when /^http/
        @deployment # Full URL provided
      when 'us1'
        "https://api.sumologic.com/api/#{API_VERSION}"
      when 'us2'
        "https://api.us2.sumologic.com/api/#{API_VERSION}"
      when 'eu'
        "https://api.eu.sumologic.com/api/#{API_VERSION}"
      when 'au'
        "https://api.au.sumologic.com/api/#{API_VERSION}"
      else
        "https://api.#{@deployment}.sumologic.com/api/#{API_VERSION}"
      end
    end
  end
end
