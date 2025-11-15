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

    it 'uses MAX_THREADS constant' do
      items = (1..20).to_a
      thread_ids = []
      mutex = Mutex.new

      worker.execute(items) do |n|
        mutex.synchronize { thread_ids << Thread.current.object_id }
        sleep 0.01
        n
      end

      # Should use at most MAX_THREADS (10)
      expect(thread_ids.uniq.size).to be <= described_class::MAX_THREADS
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
