# frozen_string_literal: true

module Sumologic
  module Search
    # Handles paginated fetching of search job messages
    # Supports both sequential and parallel pagination
    class Paginator
      # Number of pages to fetch in parallel
      PARALLEL_BATCH_SIZE = 5

      def initialize(http_client:, config:)
        @http = http_client
        @config = config
      end

      # Fetch all messages for a job with automatic pagination
      # Uses parallel fetching for better performance on large result sets (if enabled)
      # Returns array of message objects
      def fetch_all(job_id, limit: nil)
        # Check if parallel pagination is enabled and appropriate
        if should_use_parallel?(limit)
          fetch_parallel(job_id, limit: limit)
        else
          fetch_sequential(job_id, limit: limit)
        end
      end

      private

      # Check if we should use parallel fetching
      def should_use_parallel?(limit)
        return false unless @config.enable_parallel_pagination

        # Only use parallel for large result sets (over 20K messages / 2 pages)
        !limit || limit >= @config.max_messages_per_request * 2
      end

      # Sequential fetching (original implementation)
      def fetch_sequential(job_id, limit: nil)
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

      # Parallel fetching for large result sets
      def fetch_parallel(job_id, limit: nil)
        messages = []
        total_fetched = 0

        loop do
          pages_to_fetch = calculate_parallel_pages(limit, total_fetched)
          break if pages_to_fetch.empty?

          batches = fetch_batches_parallel(job_id, pages_to_fetch)
          total_fetched = process_batches(batches, messages, total_fetched)

          break if done_fetching?(batches, limit, total_fetched)
        end

        messages
      end

      # Process fetched batches and update counters
      def process_batches(batches, messages, total_fetched)
        batches.each do |batch|
          messages.concat(batch[:messages])
          total_fetched += batch[:messages].size
        end

        log_progress(batches.sum { |b| b[:messages].size }, total_fetched)
        total_fetched
      end

      # Check if we're done fetching messages
      def done_fetching?(batches, limit, total_fetched)
        last_batch = batches.last
        return true if last_batch[:messages].size < last_batch[:limit]
        return true if limit && total_fetched >= limit

        false
      end

      # Calculate which pages to fetch in parallel
      def calculate_parallel_pages(limit, total_fetched)
        pages = []
        offset = total_fetched

        PARALLEL_BATCH_SIZE.times do
          batch_limit = calculate_batch_limit(limit, offset)
          break if batch_limit <= 0

          pages << { offset: offset, limit: batch_limit }
          offset += batch_limit

          break if limit && offset >= limit
        end

        pages
      end

      # Fetch multiple batches in parallel
      def fetch_batches_parallel(job_id, pages)
        results = []
        mutex = Mutex.new
        threads = pages.map do |page|
          Thread.new do
            batch_messages = fetch_batch(job_id, page[:offset], page[:limit])

            mutex.synchronize do
              results << {
                offset: page[:offset],
                limit: page[:limit],
                messages: batch_messages
              }
            end
          end
        end

        threads.each(&:join)

        # Sort by offset to maintain order
        results.sort_by { |r| r[:offset] }
      end

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
