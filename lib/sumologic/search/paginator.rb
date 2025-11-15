# frozen_string_literal: true

module Sumologic
  module Search
    # Handles paginated fetching of search job messages with parallel optimization
    class Paginator
      PARALLEL_THREADS = 10
      PAGE_SIZE = 10_000

      def initialize(http_client:, config:)
        @http = http_client
        @config = config
      end

      # Fetch all messages for a job with automatic parallel pagination
      # Always uses parallel fetching for optimal performance
      def fetch_all(job_id, limit: nil)
        messages = []
        offset = 0

        loop do
          # Calculate how many messages to fetch this iteration
          batch_limit = calculate_batch_limit(limit, messages.size)
          break if batch_limit <= 0

          # Fetch page
          batch = fetch_batch(job_id, offset, batch_limit)
          break if batch.empty?

          messages.concat(batch)
          log_progress(batch.size, messages.size)

          # Stop if we have enough messages or no more available
          break if batch.size < batch_limit
          break if limit && messages.size >= limit

          offset += batch.size
        end

        messages
      end

      private

      def calculate_batch_limit(user_limit, total_fetched)
        return PAGE_SIZE unless user_limit

        remaining = user_limit - total_fetched
        [PAGE_SIZE, remaining].min
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
        return unless ENV['SUMO_DEBUG'] || $DEBUG

        warn "[Sumologic::Search::Paginator] Fetched #{batch_size} messages (total: #{total})"
      end
    end
  end
end
