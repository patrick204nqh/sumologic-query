# frozen_string_literal: true

require 'json'

module Sumologic
  module Http
    # Handles debug logging for HTTP requests and responses
    # Only logs when $DEBUG is enabled
    module DebugLogger
      module_function

      def log_request(method, uri, body)
        return unless $DEBUG

        warn "\n[DEBUG] API Request:"
        warn "  Method: #{method.to_s.upcase}"
        warn "  URL: #{uri}"
        log_request_body(body) if body
        warn ''
      end

      def log_response(response)
        return unless $DEBUG

        warn "[DEBUG] API Response:"
        warn "  Status: #{response.code} #{response.message}"
        log_response_body(response.body)
        warn ''
      end

      def log_request_body(body)
        warn "  Body: #{JSON.pretty_generate(body)}"
      rescue JSON::GeneratorError
        warn "  Body: #{body.inspect}"
      end

      def log_response_body(body)
        truncated = body.length > 500
        display_body = truncated ? "#{body[0..500]}..." : body
        warn "  Body: #{display_body}"
        warn "  (truncated, full length: #{body.length} characters)" if truncated
      end
    end
  end
end
