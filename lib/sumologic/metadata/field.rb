# frozen_string_literal: true

require_relative 'loggable'

module Sumologic
  module Metadata
    # Handles field operations
    # Uses GET /v1/fields and GET /v1/fields/builtin endpoints
    class Field
      include Loggable

      def initialize(http_client:)
        @http = http_client
      end

      # List custom fields
      #
      # @return [Array<Hash>] Array of custom field data
      def list
        data = @http.request(
          method: :get,
          path: '/fields'
        )

        fields = data['data'] || []
        log_info "Fetched #{fields.size} custom fields"
        fields
      rescue StandardError => e
        raise Error, "Failed to list fields: #{e.message}"
      end

      # List built-in fields
      #
      # @return [Array<Hash>] Array of built-in field data
      def list_builtin
        data = @http.request(
          method: :get,
          path: '/fields/builtin'
        )

        fields = data['data'] || []
        log_info "Fetched #{fields.size} built-in fields"
        fields
      rescue StandardError => e
        raise Error, "Failed to list built-in fields: #{e.message}"
      end
    end
  end
end
