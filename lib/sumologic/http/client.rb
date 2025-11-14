# frozen_string_literal: true

require 'net/http'
require 'json'
require 'uri'
require_relative 'connection_pool'

module Sumologic
  module Http
    # Handles HTTP communication with Sumo Logic API
    # Responsibilities: request execution, error handling, SSL configuration
    # Uses connection pooling for thread-safe parallel requests
    class Client
      def initialize(base_url:, authenticator:)
        @base_url = base_url
        @authenticator = authenticator
        @connection_pool = ConnectionPool.new(base_url: base_url, max_connections: 10)
      end

      # Execute HTTP request with error handling
      # Uses connection pool for thread-safe parallel execution
      def request(method:, path:, body: nil, query_params: nil)
        uri = build_uri(path, query_params)
        request = build_request(method, uri, body)

        response = execute_request(uri, request)
        handle_response(response)
      rescue Errno::ECONNRESET, Errno::EPIPE, EOFError, Net::HTTPBadResponse => e
        # Connection error - raise for retry at higher level
        raise Error, "Connection error: #{e.message}"
      end

      # Close all connections in the pool
      def close_all_connections
        @connection_pool.close_all
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
        @connection_pool.with_connection(uri) do |http|
          http.request(request)
        end
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
