# frozen_string_literal: true

require_relative '../utils/worker'

module Sumologic
  module Search
    # Fetches search messages with automatic pagination
    # Uses Worker utility for concurrent page fetching when beneficial
    class MessageFetcher
      PAGE_SIZE = 10_000

      def initialize(http_client:, config:)
        @http = http_client
        @config = config
        @worker = Utils::Worker.new
      end

      # Fetch all messages for a job with automatic pagination
      # Single page: fetches directly
      # Multiple pages: uses Worker for concurrent fetching
      def fetch_all(job_id, limit: nil)
        # Fetch first page to check size
        first_batch_limit = calculate_batch_limit(limit, 0)
        return [] if first_batch_limit <= 0

        first_batch = fetch_page(job_id, 0, first_batch_limit)
        return [] if first_batch.empty?

        # Single page result? Return immediately
        return first_batch if first_batch.size < first_batch_limit || (limit && first_batch.size >= limit)

        # Multi-page result: calculate remaining pages and fetch in parallel
        fetch_all_pages(job_id, first_batch, limit)
      end

      private

      def fetch_all_pages(job_id, first_batch, limit)
        messages = first_batch.dup
        offset = first_batch.size

        # Calculate remaining pages to fetch
        pages = calculate_remaining_pages(job_id, offset, limit)
        return messages if pages.empty?

        # Fetch remaining pages in parallel using Worker
        additional_messages = @worker.execute(pages) do |page|
          fetch_page(page[:job_id], page[:offset], page[:limit])
        end

        # Flatten and combine results
        additional_messages.each { |batch| messages.concat(batch) }

        # Respect limit if specified
        limit ? messages.first(limit) : messages
      end

      def calculate_remaining_pages(job_id, offset, limit)
        pages = []
        total_fetched = offset

        loop do
          batch_limit = calculate_batch_limit(limit, total_fetched)
          break if batch_limit <= 0

          pages << { job_id: job_id, offset: offset, limit: batch_limit }
          total_fetched += batch_limit
          offset += batch_limit

          # Stop estimating if we've planned enough
          break if pages.size >= 9 # First page + 9 more = 10 parallel fetches
          break if limit && total_fetched >= limit
        end

        pages
      end

      def calculate_batch_limit(user_limit, total_fetched)
        return PAGE_SIZE unless user_limit

        remaining = user_limit - total_fetched
        [PAGE_SIZE, remaining].min
      end

      def fetch_page(job_id, offset, limit)
        data = @http.request(
          method: :get,
          path: "/search/jobs/#{job_id}/messages",
          query_params: { offset: offset, limit: limit }
        )

        messages = data['messages'] || []
        log_progress(messages.size, offset) if messages.any?
        messages
      end

      def log_progress(batch_size, offset)
        return unless ENV['SUMO_DEBUG'] || $DEBUG

        warn "[Sumologic::Search::MessageFetcher] Fetched #{batch_size} messages at offset #{offset}"
      end
    end
  end
end
