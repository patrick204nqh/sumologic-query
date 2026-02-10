# frozen_string_literal: true

require_relative 'loggable'
require_relative 'models'

module Sumologic
  module Metadata
    # Handles monitor metadata operations via the search API
    # Uses GET /v1/monitors/search instead of recursive folder traversal
    class Monitor
      include Loggable

      VALID_STATUSES = %w[Normal Critical Warning MissingData Disabled AllTriggered].freeze

      def initialize(http_client:)
        @http = http_client
      end

      # List monitors using the search API
      # Supports server-side filtering by status and query
      #
      # @param query [String, nil] Search query to filter by name/description
      # @param status [String, nil] Monitor status filter (Normal, Critical, Warning, MissingData, Disabled, AllTriggered)
      # @param limit [Integer] Maximum number of monitors to return (default: 100)
      # @return [Array<Hash>] Array of monitor data with path info
      def list(query: nil, status: nil, limit: 100)
        validate_status!(status) if status

        monitors = []
        offset = 0

        loop do
          batch_limit = [limit - monitors.size, 100].min
          query_params = build_search_params(query: query, status: status, limit: batch_limit, offset: offset)

          data = @http.request(
            method: :get,
            path: '/monitors/search',
            query_params: query_params
          )

          items = extract_monitors(data)
          monitors.concat(items)

          log_info "Fetched #{items.size} monitors (total: #{monitors.size})"

          break if items.size < batch_limit || monitors.size >= limit
          offset += batch_limit
        end

        monitors.take(limit)
      rescue StandardError => e
        raise Error, "Failed to list monitors: #{e.message}"
      end

      # Get a specific monitor by ID
      # Returns full monitor details including query and triggers
      #
      # @param monitor_id [String] The monitor ID
      # @return [Hash] Monitor data
      def get(monitor_id)
        data = @http.request(
          method: :get,
          path: "/monitors/#{monitor_id}"
        )

        log_info "Retrieved monitor: #{data['name']} (#{monitor_id})"
        data
      rescue StandardError => e
        raise Error, "Failed to get monitor #{monitor_id}: #{e.message}"
      end

      private

      def build_search_params(query: nil, status: nil, limit: 100, offset: 0)
        params = { limit: limit, offset: offset }

        # The search endpoint requires a query parameter
        # Use monitorStatus filter within the query string
        query_parts = []
        query_parts << query if query && !query.empty?
        query_parts << "monitorStatus:#{status}" if status

        # Default to empty query if no filters (returns all monitors)
        params[:query] = query_parts.empty? ? '' : query_parts.join(' ')
        params
      end

      def extract_monitors(data)
        items = data || []
        items = items.is_a?(Array) ? items : []

        items.filter_map do |item|
          monitor = item['item'] || item
          next unless monitor['contentType'] == 'Monitor'

          # Merge path into the monitor data for output
          monitor['path'] = item['path'] if item['path']
          monitor
        end
      end

      def validate_status!(status)
        return if VALID_STATUSES.include?(status)

        raise Error,
              "Invalid monitor status '#{status}'. Valid values: #{VALID_STATUSES.join(', ')}"
      end
    end
  end
end
