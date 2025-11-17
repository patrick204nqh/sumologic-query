# frozen_string_literal: true

require_relative 'connection_pool'
require_relative 'debug_logger'
require_relative 'cookie_jar'
require_relative 'request_builder'
require_relative 'response_handler'

module Sumologic
  module Http
    # Orchestrates HTTP communication with Sumo Logic API
    # Delegates to specialized components for request building,
    # response handling, connection pooling, and cookie management
    class Client
      def initialize(base_url:, authenticator:)
        @cookie_jar = CookieJar.new
        @request_builder = RequestBuilder.new(
          base_url: base_url,
          authenticator: authenticator,
          cookie_jar: @cookie_jar
        )
        @response_handler = ResponseHandler.new
        @connection_pool = ConnectionPool.new(base_url: base_url, max_connections: 10)
      end

      # Execute HTTP request with error handling
      # Uses connection pool for thread-safe parallel execution
      def request(method:, path:, body: nil, query_params: nil)
        uri = @request_builder.build_uri(path, query_params)
        request = @request_builder.build_request(method, uri, body)

        DebugLogger.log_request(method, uri, body, request.to_hash)

        response = execute_request(uri, request)

        DebugLogger.log_response(response)

        @response_handler.handle(response)
      rescue Errno::ECONNRESET, Errno::EPIPE, EOFError, Net::HTTPBadResponse => e
        # Connection error - raise for retry at higher level
        raise Error, "Connection error: #{e.message}"
      end

      # Close all connections in the pool
      def close_all_connections
        @connection_pool.close_all
      end

      private

      def execute_request(uri, request)
        response = @connection_pool.with_connection(uri) do |http|
          http.request(request)
        end

        # Store cookies from response for subsequent requests
        @cookie_jar.store_from_response(response)

        response
      end
    end
  end
end
