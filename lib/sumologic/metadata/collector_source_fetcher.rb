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
        @worker.execute(collectors, &block)
      end
    end
  end
end
