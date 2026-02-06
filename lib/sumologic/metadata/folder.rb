# frozen_string_literal: true

require_relative 'loggable'
require_relative 'models'

module Sumologic
  module Metadata
    # Handles folder/content library operations
    # Folders organize dashboards, searches, and other content
    # NOTE: Content API uses v2, not v1
    class Folder
      include Loggable

      # @param http_client [Http::Client] HTTP client configured for v2 API
      def initialize(http_client:)
        @http = http_client
      end

      # Get the personal folder for the current user
      # Returns folder with children
      #
      # @return [Hash] Personal folder data
      def personal
        data = @http.request(
          method: :get,
          path: '/content/folders/personal'
        )

        log_info "Retrieved personal folder: #{data['name']}"
        data
      rescue StandardError => e
        raise Error, "Failed to get personal folder: #{e.message}"
      end

      # Get the global (admin) folder
      # Requires admin privileges
      #
      # @return [Hash] Global folder data
      def global
        data = @http.request(
          method: :get,
          path: '/content/folders/global'
        )

        log_info "Retrieved global folder: #{data['name']}"
        data
      rescue StandardError => e
        raise Error, "Failed to get global folder: #{e.message}"
      end

      # Get a specific folder by ID
      # Returns folder details with children
      #
      # @param folder_id [String] The folder ID
      # @return [Hash] Folder data with children
      def get(folder_id)
        data = @http.request(
          method: :get,
          path: "/content/folders/#{folder_id}"
        )

        log_info "Retrieved folder: #{data['name']} (#{folder_id})"
        data
      rescue StandardError => e
        raise Error, "Failed to get folder #{folder_id}: #{e.message}"
      end

      # Get folder status (async job status)
      # Used when folder operations return a job ID
      #
      # @param job_id [String] The job ID
      # @return [Hash] Job status
      def job_status(job_id)
        @http.request(
          method: :get,
          path: "/content/folders/#{job_id}/status"
        )
      rescue StandardError => e
        raise Error, "Failed to get folder job status: #{e.message}"
      end

      # Get the admin recommended folder
      # Contains content shared by admins
      #
      # @return [Hash] Admin recommended folder data
      def admin_recommended
        data = @http.request(
          method: :get,
          path: '/content/folders/adminRecommended'
        )

        log_info 'Retrieved admin recommended folder'
        data
      rescue StandardError => e
        raise Error, "Failed to get admin recommended folder: #{e.message}"
      end

      # List all items in a folder (recursive tree)
      # Builds a tree structure of all content
      #
      # @param folder_id [String] Starting folder ID (nil for personal)
      # @param max_depth [Integer] Maximum recursion depth (default: 3)
      # @return [Hash] Folder tree with nested children
      def tree(folder_id: nil, max_depth: 3)
        root = folder_id ? get(folder_id) : personal
        build_tree(root, 0, max_depth)
      rescue StandardError => e
        raise Error, "Failed to build folder tree: #{e.message}"
      end

      private

      def build_tree(folder, depth, max_depth)
        return folder if depth >= max_depth

        children = folder['children'] || []
        folder['children'] = children.map do |child|
          if child['itemType'] == 'Folder'
            begin
              child_folder = get(child['id'])
              build_tree(child_folder, depth + 1, max_depth)
            rescue StandardError => e
              log_error "Failed to fetch child folder #{child['id']}: #{e.message}"
              child
            end
          else
            child
          end
        end

        folder
      end
    end
  end
end
