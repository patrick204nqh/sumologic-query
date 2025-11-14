# frozen_string_literal: true

module Sumologic
  module Search
    # Manages search job lifecycle: create, poll, fetch, delete
    class Job
      def initialize(http_client:, config:)
        @http = http_client
        @config = config
        @poller = Poller.new(http_client: http_client, config: config)
        @paginator = Paginator.new(http_client: http_client, config: config)
      end

      # Execute a complete search workflow
      # Returns array of messages
      def execute(query:, from_time:, to_time:, time_zone: 'UTC', limit: nil)
        job_id = create(query, from_time, to_time, time_zone)
        @poller.poll(job_id)
        messages = @paginator.fetch_all(job_id, limit: limit)
        delete(job_id)
        messages
      rescue StandardError => e
        delete(job_id) if job_id
        raise Error, "Search failed: #{e.message}"
      end

      private

      def create(query, from_time, to_time, time_zone)
        data = @http.request(
          method: :post,
          path: '/search/jobs',
          body: {
            query: query,
            from: from_time,
            to: to_time,
            timeZone: time_zone
          }
        )

        raise Error, "Failed to create job: #{data['message']}" unless data['id']

        log_info "Created search job: #{data['id']}"
        data['id']
      end

      def delete(job_id)
        return unless job_id

        @http.request(
          method: :delete,
          path: "/search/jobs/#{job_id}"
        )
        log_info "Deleted search job: #{job_id}"
      rescue StandardError => e
        log_error "Failed to delete job #{job_id}: #{e.message}"
      end

      def log_info(message)
        warn "[Sumologic::Search::Job] #{message}" if ENV['SUMO_DEBUG'] || $DEBUG
      end

      def log_error(message)
        warn "[Sumologic::Search::Job ERROR] #{message}"
      end
    end
  end
end
