# frozen_string_literal: true

module Sumologic
  module Utils
    # Generic worker pool for parallel execution of tasks
    # Uses Queue + Mutex pattern for thread-safe concurrent processing
    #
    # This utility abstracts the parallel execution pattern used across the codebase
    # (metadata fetching, search pagination, etc.) into a reusable component.
    #
    # Example:
    #   worker = Worker.new
    #   results = worker.execute(items) do |item|
    #     fetch_data(item)
    #   end
    class Worker
      MAX_THREADS = 10

      # Execute work items using a thread pool
      # Returns array of results from the block execution
      #
      # @param items [Array] Work items to process
      # @yield [item] Block to execute for each item
      # @return [Array] Results from block executions (nil results are filtered out)
      def execute(items, &block)
        return [] if items.empty?

        result = []
        mutex = Mutex.new
        queue = create_work_queue(items)
        threads = create_workers(queue, result, mutex, &block)

        threads.each(&:join)
        result
      end

      private

      def create_work_queue(items)
        queue = Queue.new
        items.each { |item| queue << item }
        queue
      end

      def create_workers(queue, result, mutex, &block)
        worker_count = [MAX_THREADS, queue.size].min

        Array.new(worker_count) do
          Thread.new { process_queue(queue, result, mutex, &block) }
        end
      end

      def process_queue(queue, result, mutex, &block)
        until queue.empty?
          item = pop_safely(queue)
          break unless item

          process_item(item, result, mutex, &block)
        end
      end

      def pop_safely(queue)
        queue.pop(true)
      rescue ThreadError
        nil
      end

      def process_item(item, result, mutex, &block)
        item_result = block.call(item)

        mutex.synchronize do
          result << item_result if item_result
        end
      end
    end
  end
end
