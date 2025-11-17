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
        else
          handle_generic_error(response)
        end
      end

      private

      def parse_success(response)
        JSON.parse(response.body)
      end

      def handle_authentication_error(response)
        raise AuthenticationError, "Authentication failed: #{response.body}"
      end

      def handle_rate_limit_error(response)
        raise Error, "Rate limit exceeded: #{response.body}"
      end

      def handle_generic_error(response)
        raise Error, "HTTP #{response.code}: #{response.body}"
      end
    end
  end
end
