# frozen_string_literal: true

require_relative 'loggable'
require_relative 'models'

module Sumologic
  module Metadata
    # Handles collector metadata operations
    class Collector
      include Loggable

      def initialize(http_client:)
        @http = http_client
      end

      # List collectors with optional client-side filtering
      #
      # @param query [String, nil] Filter by name or category (case-insensitive substring match)
      # @param limit [Integer, nil] Maximum number of collectors to return
      # @return [Array<Hash>] Array of collector objects
      def list(query: nil, limit: nil)
        data = @http.request(
          method: :get,
          path: '/collectors'
        )

        collectors = data['collectors'] || []
        log_info "Found #{collectors.size} collectors"

        collectors = filter_by_query(collectors, query) if query
        collectors = collectors.take(limit) if limit

        collectors
      rescue StandardError => e
        raise Error, "Failed to list collectors: #{e.message}"
      end

      private

      def filter_by_query(collectors, query)
        pattern = query.downcase
        collectors.select do |c|
          name = (c['name'] || '').downcase
          category = (c['category'] || '').downcase
          name.include?(pattern) || category.include?(pattern)
        end
      end
    end
  end
end
