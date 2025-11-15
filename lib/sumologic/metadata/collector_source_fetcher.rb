# frozen_string_literal: true

require_relative '../utils/worker'

module Sumologic
  module Metadata
    # Fetches sources from multiple collectors efficiently
    # Uses Worker utility for concurrent fetching
    class CollectorSourceFetcher
      def initialize
        @worker = Utils::Worker.new
      end

      # Fetch sources for collectors concurrently
      # Returns array of results with collector info and sources
      def fetch_all(collectors, &block)
        @worker.execute(collectors, callbacks: {
                          start: ->(workers, total) { log_start(workers, total) },
                          progress: ->(done, total) { log_progress(done, total) },
                          finish: ->(results, duration) { log_finish(results.size, duration) }
                        }, &block)
      end

      private

      def log_start(workers, total)
        warn "  Created #{workers} workers for #{total} collectors" if ENV['SUMO_DEBUG'] || $DEBUG
      end

      def log_progress(done, total)
        return unless ENV['SUMO_DEBUG'] || $DEBUG

        warn "  Progress: #{done}/#{total} collectors processed" if (done % 10).zero? || done == total
      end

      def log_finish(count, duration)
        warn "  Fetched sources from #{count} collectors in #{duration.round(2)}s" if ENV['SUMO_DEBUG'] || $DEBUG
      end
    end
  end
end
