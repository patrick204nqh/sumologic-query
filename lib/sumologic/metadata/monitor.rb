# frozen_string_literal: true

require_relative 'loggable'
require_relative 'models'

module Sumologic
  module Metadata
    # Handles monitor metadata operations
    # Monitors are alerting rules in Sumo Logic
    class Monitor
      include Loggable

      def initialize(http_client:)
        @http = http_client
      end

      # List all monitors in the monitors library
      # Recursively collects monitors from the folder structure
      #
      # @param limit [Integer] Maximum number of monitors to return (default: 100)
      # @return [Array<Hash>] Array of monitor data
      def list(limit: 100)
        root_folder = root
        monitors = collect_monitors(root_folder, limit)
        log_info "Found #{monitors.size} monitors"
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

      # Get the root monitors folder
      # Returns the root folder with children
      #
      # @return [Hash] Root folder data
      def root
        data = @http.request(
          method: :get,
          path: '/monitors/root'
        )

        log_info 'Retrieved monitors root folder'
        data
      rescue StandardError => e
        raise Error, "Failed to get monitors root: #{e.message}"
      end

      # Search monitors by name or description
      # Returns matching monitors
      #
      # @param query [String] Search query
      # @param limit [Integer] Maximum results (default: 100)
      # @return [Array<Hash>] Matching monitors
      def search(query:, limit: 100)
        # Use list and filter client-side since API may not support search
        monitors = list(limit: limit * 2) # Fetch extra to account for filtering
        query_lower = query.downcase

        filtered = monitors.select do |m|
          name_match = m['name']&.downcase&.include?(query_lower)
          desc_match = m['description']&.downcase&.include?(query_lower)
          name_match || desc_match
        end

        filtered.take(limit)
      end

      # List monitors by status (enabled/disabled)
      #
      # @param enabled [Boolean] Filter by enabled status
      # @param limit [Integer] Maximum results
      # @return [Array<Hash>] Filtered monitors
      def list_by_status(enabled:, limit: 100)
        monitors = list(limit: limit * 2)

        filtered = monitors.select do |m|
          if enabled
            m['isDisabled'] != true
          else
            m['isDisabled'] == true
          end
        end

        filtered.take(limit)
      end

      private

      # Recursively collect monitors from folder structure
      def collect_monitors(folder, limit, collected = [])
        return collected if collected.size >= limit

        children = folder['children'] || []
        children.each do |child|
          break if collected.size >= limit

          if child['contentType'] == 'Monitor'
            collected << child
          elsif child['contentType'] == 'Folder'
            # Recursively process subfolders
            begin
              subfolder = @http.request(method: :get, path: "/monitors/#{child['id']}")
              collect_monitors(subfolder, limit, collected)
            rescue StandardError => e
              log_error "Failed to fetch subfolder #{child['id']}: #{e.message}"
            end
          end
        end

        collected
      end
    end
  end
end
