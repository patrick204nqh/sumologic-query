# frozen_string_literal: true

require 'net/http'
require 'json'
require 'uri'

module Sumologic
  module Http
    # Handles HTTP communication with Sumo Logic API
    # Responsibilities: request execution, error handling, SSL configuration
    class Client
      READ_TIMEOUT = 60
      OPEN_TIMEOUT = 10

      def initialize(base_url:, authenticator:)
        @base_url = base_url
        @authenticator = authenticator
      end

      # Execute HTTP request with error handling
      def request(method:, path:, body: nil, query_params: nil)
        uri = build_uri(path, query_params)
        request = build_request(method, uri, body)

        response = execute_request(uri, request)
        handle_response(response)
      end

      private

      def build_uri(path, query_params)
        uri = URI("#{@base_url}#{path}")
        uri.query = URI.encode_www_form(query_params) if query_params
        uri
      end

      def build_request(method, uri, body)
        request_class = case method
                        when :get then Net::HTTP::Get
                        when :post then Net::HTTP::Post
                        when :delete then Net::HTTP::Delete
                        else raise ArgumentError, "Unsupported HTTP method: #{method}"
                        end

        request = request_class.new(uri)
        request['Authorization'] = @authenticator.auth_header
        request['Accept'] = 'application/json'

        if body
          request['Content-Type'] = 'application/json'
          request.body = body.to_json
        end

        request
      end

      def execute_request(uri, request)
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true
        http.read_timeout = READ_TIMEOUT
        http.open_timeout = OPEN_TIMEOUT

        http.request(request)
      end

      def handle_response(response)
        case response.code.to_i
        when 200..299
          JSON.parse(response.body)
        when 401, 403
          raise AuthenticationError, "Authentication failed: #{response.body}"
        when 429
          raise Error, "Rate limit exceeded: #{response.body}"
        else
          raise Error, "HTTP #{response.code}: #{response.body}"
        end
      end
    end
  end
end
