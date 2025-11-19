# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sumologic::Utils::Worker do
  let(:worker) { described_class.new }

  describe '#execute' do
    it 'processes items in parallel' do
      items = (1..10).to_a
      results = worker.execute(items) { |n| n * 2 }

      expect(results.size).to eq(10)
      expect(results.sort).to eq([2, 4, 6, 8, 10, 12, 14, 16, 18, 20])
    end

    it 'handles empty items' do
      results = worker.execute([]) { |n| n * 2 }
      expect(results).to eq([])
    end

    it 'filters out nil results' do
      items = [1, 2, 3, 4, 5]
      results = worker.execute(items) do |n|
        n.even? ? n * 2 : nil
      end

      expect(results.sort).to eq([4, 8])
    end

    it 'respects max_threads configuration' do
      items = (1..20).to_a
      thread_ids = []
      mutex = Mutex.new

      worker.execute(items) do |n|
        mutex.synchronize { thread_ids << Thread.current.object_id }
        sleep 0.01
        n
      end

      # Should use at most DEFAULT_MAX_THREADS (10)
      expect(thread_ids.uniq.size).to be <= described_class::DEFAULT_MAX_THREADS
    end

    it 'allows custom max_threads' do
      custom_worker = described_class.new(max_threads: 2)
      items = (1..10).to_a
      thread_ids = []
      mutex = Mutex.new

      custom_worker.execute(items) do |n|
        mutex.synchronize { thread_ids << Thread.current.object_id }
        sleep 0.01
        n
      end

      # Should use at most 2 threads
      expect(thread_ids.uniq.size).to be <= 2
    end

    it 'applies request delay when configured' do
      delay_worker = described_class.new(request_delay: 0.1)
      items = [1, 2, 3]

      start_time = Time.now
      delay_worker.execute(items) { |n| n }
      duration = Time.now - start_time

      # With 0.1s delay per item and up to 10 threads, should take at least 0.1s
      expect(duration).to be >= 0.1
    end

    it 'is thread-safe' do
      items = (1..100).to_a
      results = worker.execute(items) { |n| n }

      expect(results.size).to eq(100)
      expect(results.sort).to eq(items)
    end

    it 'handles exceptions in worker block' do
      items = [1, 2, 3]

      expect do
        worker.execute(items) do |n|
          raise 'Test error' if n == 2

          n
        end
      end.to raise_error(StandardError, /Test error/)
    end
  end
end
