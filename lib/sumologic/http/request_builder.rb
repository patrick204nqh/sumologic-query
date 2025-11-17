# frozen_string_literal: true

require 'net/http'
require 'json'
require 'uri'

module Sumologic
  module Http
    # Builds HTTP requests with proper headers, authentication, and cookies
    class RequestBuilder
      def initialize(base_url:, authenticator:, cookie_jar:)
        @base_url = base_url
        @authenticator = authenticator
        @cookie_jar = cookie_jar
      end

      # Build complete URI from path and query parameters
      def build_uri(path, query_params = nil)
        uri = URI("#{@base_url}#{path}")
        uri.query = URI.encode_www_form(query_params) if query_params
        uri
      end

      # Build HTTP request with all necessary headers
      def build_request(method, uri, body = nil)
        request = create_request_object(method, uri)
        add_headers(request)
        add_body(request, body) if body
        request
      end

      private

      def create_request_object(method, uri)
        request_class = request_class_for(method)
        request_class.new(uri)
      end

      def request_class_for(method)
        case method
        when :get then Net::HTTP::Get
        when :post then Net::HTTP::Post
        when :delete then Net::HTTP::Delete
        else raise ArgumentError, "Unsupported HTTP method: #{method}"
        end
      end

      def add_headers(request)
        request['Authorization'] = @authenticator.auth_header
        request['Accept'] = 'application/json'

        # Add cookies if available
        cookie_header = @cookie_jar.to_header
        request['Cookie'] = cookie_header if cookie_header
      end

      def add_body(request, body)
        request['Content-Type'] = 'application/json'
        request.body = body.to_json
      end
    end
  end
end
