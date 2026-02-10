# frozen_string_literal: true

require_relative 'loggable'

module Sumologic
  module Metadata
    # Handles content library operations
    # Uses v2 content API endpoints for path lookup and export
    class Content
      include Loggable

      EXPORT_POLL_INTERVAL = 2 # seconds
      EXPORT_MAX_WAIT = 120 # seconds

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

      # Export a content item as JSON
      # Handles the async job lifecycle: start → poll → fetch result
      #
      # @param content_id [String] The content item ID to export
      # @return [Hash] Exported content data
      def export(content_id)
        # Start export job
        job = @http.request(
          method: :post,
          path: "/content/#{content_id}/export"
        )
        job_id = job['id']
        log_info "Started export job #{job_id} for content #{content_id}"

        # Poll until complete
        poll_export_status(content_id, job_id)

        # Fetch result
        result = @http.request(
          method: :get,
          path: "/content/#{content_id}/export/#{job_id}/result"
        )

        log_info "Export complete for content #{content_id}"
        result
      rescue StandardError => e
        raise Error, "Failed to export content #{content_id}: #{e.message}"
      end

      private

      def poll_export_status(content_id, job_id)
        start_time = Time.now

        loop do
          elapsed = Time.now - start_time
          raise TimeoutError, "Export job timed out after #{EXPORT_MAX_WAIT}s" if elapsed > EXPORT_MAX_WAIT

          status = @http.request(
            method: :get,
            path: "/content/#{content_id}/export/#{job_id}/status"
          )

          state = status['status']
          log_info "Export status: #{state}"

          case state
          when 'Success'
            return
          when 'Failed'
            raise Error, "Export job failed: #{status['error']&.dig('message') || 'unknown error'}"
          end

          sleep EXPORT_POLL_INTERVAL
        end
      end
    end
  end
end
