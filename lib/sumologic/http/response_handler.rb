# frozen_string_literal: true

require 'json'

module Sumologic
  module Http
    # Handles HTTP response parsing and error handling
    class ResponseHandler
      # Parse response and handle errors
      def handle(response)
        case response.code.to_i
        when 200..299
          parse_success(response)
        when 401, 403
          handle_authentication_error(response)
        when 429
          handle_rate_limit_error(response)
        when 500..599
          handle_server_error(response)
        else
          handle_generic_error(response)
        end
      end

      # Check if response indicates a retryable error
      def retryable?(response)
        code = response.code.to_i
        code == 429 || code.between?(500, 599)
      end

      # Extract rate limit info from response headers
      def extract_rate_limit_info(response)
        {
          retry_after: parse_retry_after(response),
          limit: response['X-RateLimit-Limit']&.to_i,
          remaining: response['X-RateLimit-Remaining']&.to_i,
          reset_at: parse_reset_time(response)
        }
      end

      private

      def parse_success(response)
        return {} if response.body.nil? || response.body.empty?

        JSON.parse(response.body)
      end

      def handle_authentication_error(response)
        raise AuthenticationError, "Authentication failed: #{response.body}"
      end

      def handle_rate_limit_error(response)
        info = extract_rate_limit_info(response)
        message = 'Rate limit exceeded'
        message += " (retry after #{info[:retry_after]}s)" if info[:retry_after]

        raise RateLimitError.new(
          message,
          retry_after: info[:retry_after],
          limit: info[:limit],
          remaining: info[:remaining],
          reset_at: info[:reset_at]
        )
      end

      def handle_server_error(response)
        raise Error, "Server error HTTP #{response.code}: #{response.body}"
      end

      def handle_generic_error(response)
        raise Error, "HTTP #{response.code}: #{response.body}"
      end

      def parse_retry_after(response)
        # Try Retry-After header first (standard HTTP)
        retry_after = response['Retry-After']
        return retry_after.to_i if retry_after&.match?(/^\d+$/)

        # Try X-RateLimit-Reset (common alternative)
        reset = response['X-RateLimit-Reset']
        return nil unless reset

        # Reset can be seconds or Unix timestamp
        reset_val = reset.to_i
        if reset_val > 1_000_000_000 # Likely a Unix timestamp
          [reset_val - Time.now.to_i, 1].max
        else
          reset_val
        end
      end

      def parse_reset_time(response)
        reset = response['X-RateLimit-Reset']
        return nil unless reset

        reset_val = reset.to_i
        if reset_val > 1_000_000_000 # Unix timestamp
          Time.at(reset_val)
        else
          Time.now + reset_val
        end
      end
    end
  end
end
