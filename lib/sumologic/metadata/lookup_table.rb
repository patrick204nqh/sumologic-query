# frozen_string_literal: true

require_relative 'loggable'

module Sumologic
  module Metadata
    # Handles lookup table operations
    # Uses GET /v1/lookupTables/{id} endpoint
    # Note: There is no list-all endpoint for lookup tables
    class LookupTable
      include Loggable

      def initialize(http_client:)
        @http = http_client
      end

      # Get a specific lookup table by ID
      #
      # @param lookup_id [String] The lookup table ID
      # @return [Hash] Lookup table data
      def get(lookup_id)
        data = @http.request(
          method: :get,
          path: "/lookupTables/#{lookup_id}"
        )

        log_info "Retrieved lookup table: #{data['name']} (#{lookup_id})"
        data
      rescue StandardError => e
        raise Error, "Failed to get lookup table #{lookup_id}: #{e.message}"
      end
    end
  end
end
