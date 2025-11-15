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
      # @param callbacks [Hash] Optional callbacks for progress tracking:
      #   - :start => ->(worker_count, total_items) { }
      #   - :progress => ->(completed_count, total_items) { }
      #   - :finish => ->(results, duration) { }
      # @yield [item] Block to execute for each item
      # @return [Array] Results from block executions (nil results are filtered out)
      def execute(items, callbacks: {}, &block)
        return [] if items.empty?

        start_time = Time.now
        context = {
          result: [],
          completed: { count: 0 },
          mutex: Mutex.new,
          total_items: items.size,
          callbacks: callbacks
        }

        queue = create_work_queue(items)
        worker_count = [MAX_THREADS, queue.size].min

        # Callback: start
        callbacks[:start]&.call(worker_count, items.size)

        threads = create_workers(queue, context, &block)

        threads.each(&:join)

        # Callback: finish
        duration = Time.now - start_time
        callbacks[:finish]&.call(context[:result], duration)

        context[:result]
      end

      private

      def create_work_queue(items)
        queue = Queue.new
        items.each { |item| queue << item }
        queue
      end

      def create_workers(queue, context, &block)
        worker_count = [MAX_THREADS, queue.size].min

        Array.new(worker_count) do
          Thread.new { process_queue(queue, context, &block) }
        end
      end

      def process_queue(queue, context, &block)
        until queue.empty?
          item = pop_safely(queue)
          break unless item

          process_item(item, context[:result], context[:mutex], &block)

          # Callback: progress (thread-safe)
          next unless context[:callbacks][:progress]

          context[:mutex].synchronize do
            context[:completed][:count] += 1
            context[:callbacks][:progress].call(context[:completed][:count], context[:total_items])
          end
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
