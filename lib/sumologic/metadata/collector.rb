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

      # List all collectors
      # Returns array of collector objects
      def list
        data = @http.request(
          method: :get,
          path: '/collectors'
        )

        collectors = data['collectors'] || []
        log_info "Found #{collectors.size} collectors"
        collectors
      rescue StandardError => e
        raise Error, "Failed to list collectors: #{e.message}"
      end
    end
  end
end
