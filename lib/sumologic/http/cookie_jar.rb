# frozen_string_literal: true

module Sumologic
  module Http
    # Simple cookie jar for storing and managing HTTP cookies
    # Handles Set-Cookie response headers and Cookie request headers
    class CookieJar
      def initialize
        @cookies = {}
      end

      # Store cookies from response Set-Cookie headers
      def store_from_response(response)
        return unless response['Set-Cookie']

        Array(response['Set-Cookie']).each do |cookie_header|
          parse_and_store(cookie_header)
        end
      end

      # Format cookies for Cookie request header
      # Returns nil if no cookies stored
      def to_header
        return nil if @cookies.empty?

        @cookies.map { |name, value| "#{name}=#{value}" }.join('; ')
      end

      # Check if any cookies are stored
      def any?
        @cookies.any?
      end

      # Clear all stored cookies
      def clear
        @cookies.clear
      end

      private

      def parse_and_store(cookie_header)
        # Parse cookie name=value (ignore path, domain, expires, etc.)
        # Example: "session_id=abc123; Path=/; HttpOnly"
        return unless cookie_header =~ /^([^=]+)=([^;]+)/

        name = Regexp.last_match(1).strip
        value = Regexp.last_match(2).strip
        @cookies[name] = value
      end
    end
  end
end
