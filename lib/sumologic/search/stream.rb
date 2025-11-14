# frozen_string_literal: true

module Sumologic
  module Search
    # Provides streaming interface for search results
    # Returns an Enumerator that yields messages as they are fetched
    # Reduces memory usage by not loading all results at once
    class Stream
      def initialize(paginator:)
        @paginator = paginator
      end

      # Create an enumerator that streams messages from a job
      # Yields messages one at a time as pages are fetched
      def each(job_id, limit: nil, &block)
        return enum_for(:each, job_id, limit: limit) unless block_given?

        stream_messages(job_id, limit: limit, &block)
      end

      private

      def stream_messages(job_id, limit: nil)
        offset = 0
        total_yielded = 0

        loop do
          batch_limit = calculate_batch_limit(limit, total_yielded)
          break if batch_limit <= 0

          batch = fetch_batch(job_id, offset, batch_limit)
          break if batch.empty?

          total_yielded = yield_batch_messages(batch, total_yielded, limit, &Proc.new)

          break if done_streaming?(batch, batch_limit, limit, total_yielded)

          offset += batch.size
        end
      end

      # Yield messages from batch and return updated count
      def yield_batch_messages(batch, total_yielded, limit)
        batch.each do |message|
          yield message
          total_yielded += 1
          break if limit_reached?(limit, total_yielded)
        end
        total_yielded
      end

      # Check if we've reached the limit
      def limit_reached?(limit, total_yielded)
        limit && total_yielded >= limit
      end

      # Check if we're done streaming
      def done_streaming?(batch, batch_limit, limit, total_yielded)
        return true if batch.size < batch_limit # No more messages
        return true if limit_reached?(limit, total_yielded)

        false
      end

      def calculate_batch_limit(user_limit, total_yielded)
        page_size = @paginator.instance_variable_get(:@config).max_messages_per_request

        if user_limit
          [page_size, user_limit - total_yielded].min
        else
          page_size
        end
      end

      def fetch_batch(job_id, offset, limit)
        @paginator.send(:fetch_batch, job_id, offset, limit)
      end
    end
  end
end
