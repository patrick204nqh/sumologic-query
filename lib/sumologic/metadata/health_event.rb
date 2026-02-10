# frozen_string_literal: true

require_relative 'loggable'

module Sumologic
  module Metadata
    # Handles health event operations
    # Uses GET /v1/healthEvents endpoint
    class HealthEvent
      include Loggable

      def initialize(http_client:)
        @http = http_client
      end

      # List all health events
      #
      # @param limit [Integer] Maximum events to return (default: 100)
      # @return [Array<Hash>] Array of health event data
      def list(limit: 100)
        data = @http.request(
          method: :get,
          path: '/healthEvents',
          query_params: { limit: limit }
        )

        events = data['data'] || []
        log_info "Fetched #{events.size} health events"
        events
      rescue StandardError => e
        raise Error, "Failed to list health events: #{e.message}"
      end
    end
  end
end
