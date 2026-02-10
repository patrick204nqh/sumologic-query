# frozen_string_literal: true

require_relative 'loggable'
require_relative 'models'

module Sumologic
  module Metadata
    # Handles dashboard operations via v2 API
    # Uses GET /v2/dashboards endpoints
    class Dashboard
      include Loggable

      def initialize(http_client:)
        @http = http_client
      end

      # List all dashboards
      # Returns array of dashboard objects
      #
      # @param limit [Integer] Maximum number of dashboards to return (default: 100)
      # @return [Array<Hash>] Array of dashboard data
      def list(limit: 100)
        dashboards = []
        token = nil

        loop do
          query_params = { limit: [limit - dashboards.size, 100].min }
          query_params[:token] = token if token

          data = @http.request(
            method: :get,
            path: '/dashboards',
            query_params: query_params
          )

          batch = data['dashboards'] || []
          dashboards.concat(batch)

          log_info "Fetched #{batch.size} dashboards (total: #{dashboards.size})"

          # Check for pagination
          token = data['next']
          break if token.nil? || dashboards.size >= limit
        end

        dashboards.take(limit)
      rescue StandardError => e
        raise Error, "Failed to list dashboards: #{e.message}"
      end

      # Get a specific dashboard by ID
      # Returns full dashboard details including panels
      #
      # @param dashboard_id [String] The dashboard ID
      # @return [Hash] Dashboard data
      def get(dashboard_id)
        data = @http.request(
          method: :get,
          path: "/dashboards/#{dashboard_id}"
        )

        log_info "Retrieved dashboard: #{data['title']} (#{dashboard_id})"
        data
      rescue StandardError => e
        raise Error, "Failed to get dashboard #{dashboard_id}: #{e.message}"
      end

      # Search dashboards by title or description
      # Returns matching dashboards
      #
      # @param query [String] Search query
      # @param limit [Integer] Maximum results (default: 100)
      # @return [Array<Hash>] Matching dashboards
      def search(query:, limit: 100)
        # Use list and filter client-side
        dashboards = list(limit: limit * 2)
        query_lower = query.downcase

        filtered = dashboards.select do |d|
          title_match = d['title']&.downcase&.include?(query_lower)
          desc_match = d['description']&.downcase&.include?(query_lower)
          title_match || desc_match
        end

        filtered.take(limit)
      end

      # List dashboards in a specific folder
      #
      # @param folder_id [String] Folder ID to search in
      # @param limit [Integer] Maximum results
      # @return [Array<Hash>] Dashboards in folder
      def list_by_folder(folder_id:, limit: 100)
        dashboards = list(limit: limit * 2)

        filtered = dashboards.select do |d|
          d['folderId'] == folder_id
        end

        filtered.take(limit)
      end
    end
  end
end
