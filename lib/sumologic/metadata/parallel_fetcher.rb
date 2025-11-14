# frozen_string_literal: true

module Sumologic
  module Metadata
    # Handles parallel fetching of sources from multiple collectors
    class ParallelFetcher
      def initialize(max_threads: 10)
        @max_threads = max_threads
      end

      # Fetch sources for collectors in parallel
      # Returns array of results with collector info and sources
      def fetch_all(collectors, &block)
        result = []
        mutex = Mutex.new
        queue = create_work_queue(collectors)
        threads = create_workers(queue, result, mutex, &block)

        threads.each(&:join)
        result
      end

      private

      def create_work_queue(collectors)
        queue = Queue.new
        collectors.each { |collector| queue << collector }
        queue
      end

      def create_workers(queue, result, mutex, &block)
        worker_count = [@max_threads, queue.size].min

        Array.new(worker_count) do
          Thread.new { process_queue(queue, result, mutex, &block) }
        end
      end

      def process_queue(queue, result, mutex, &block)
        until queue.empty?
          collector = pop_safely(queue)
          break unless collector

          process_collector(collector, result, mutex, &block)
        end
      end

      def pop_safely(queue)
        queue.pop(true)
      rescue ThreadError
        nil
      end

      def process_collector(collector, result, mutex, &block)
        collector_result = block.call(collector)

        mutex.synchronize do
          result << collector_result if collector_result
        end
      end
    end
  end
end
