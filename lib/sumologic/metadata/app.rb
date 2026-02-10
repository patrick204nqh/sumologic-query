# frozen_string_literal: true

require_relative 'loggable'

module Sumologic
  module Metadata
    # Handles app catalog operations
    # Uses GET /v1/apps endpoint
    # Note: This lists the app catalog (available apps), not installed apps
    class App
      include Loggable

      def initialize(http_client:)
        @http = http_client
      end

      # List available apps from the Sumo Logic app catalog
      #
      # @return [Array<Hash>] Array of app data
      def list
        data = @http.request(
          method: :get,
          path: '/apps'
        )

        apps = data['apps'] || []
        log_info "Fetched #{apps.size} apps from catalog"
        apps
      rescue StandardError => e
        raise Error, "Failed to list apps: #{e.message}"
      end
    end
  end
end
