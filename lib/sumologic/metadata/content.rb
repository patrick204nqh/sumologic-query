# frozen_string_literal: true

require_relative 'loggable'

module Sumologic
  module Metadata
    # Handles content library path-based operations
    # Uses GET /v2/content/path endpoint
    class Content
      include Loggable

      def initialize(http_client:)
        @http = http_client
      end

      # Get a content item by its library path
      # Returns item ID, type, name, and parent folder
      #
      # @param path [String] Content library path (e.g., '/Library/Users/me/My Search')
      # @return [Hash] Content item data
      def get_by_path(path)
        data = @http.request(
          method: :get,
          path: '/content/path',
          query_params: { path: path }
        )

        log_info "Retrieved content at path: #{path}"
        data
      rescue StandardError => e
        raise Error, "Failed to get content at path '#{path}': #{e.message}"
      end
    end
  end
end
