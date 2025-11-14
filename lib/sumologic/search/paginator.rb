# frozen_string_literal: true

module Sumologic
  module Search
    # Handles paginated fetching of search job messages
    class Paginator
      def initialize(http_client:, config:)
        @http = http_client
        @config = config
      end

      # Fetch all messages for a job with automatic pagination
      # Returns array of message objects
      def fetch_all(job_id, limit: nil)
        messages = []
        offset = 0
        total_fetched = 0

        loop do
          batch_limit = calculate_batch_limit(limit, total_fetched)
          break if batch_limit <= 0

          batch = fetch_batch(job_id, offset, batch_limit)
          messages.concat(batch)
          total_fetched += batch.size

          log_progress(batch.size, total_fetched)

          break if batch.size < batch_limit # No more messages
          break if limit && total_fetched >= limit

          offset += batch.size
        end

        messages
      end

      private

      def calculate_batch_limit(user_limit, total_fetched)
        if user_limit
          [@config.max_messages_per_request, user_limit - total_fetched].min
        else
          @config.max_messages_per_request
        end
      end

      def fetch_batch(job_id, offset, limit)
        data = @http.request(
          method: :get,
          path: "/search/jobs/#{job_id}/messages",
          query_params: { offset: offset, limit: limit }
        )

        data['messages'] || []
      end

      def log_progress(batch_size, total)
        log_info "Fetched #{batch_size} messages (total: #{total})"
      end

      def log_info(message)
        warn "[Sumologic::Search::Paginator] #{message}" if ENV['SUMO_DEBUG'] || $DEBUG
      end
    end
  end
end
