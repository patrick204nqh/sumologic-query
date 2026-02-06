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
    #
    # Features automatic retry with exponential backoff for:
    # - Rate limit errors (429)
    # - Server errors (5xx)
    # - Connection errors
    class Client
      # Errors that are safe to retry
      RETRYABLE_EXCEPTIONS = [
        Errno::ECONNRESET,
        Errno::EPIPE,
        Errno::ETIMEDOUT,
        Errno::ECONNREFUSED,
        EOFError,
        Net::HTTPBadResponse,
        Net::OpenTimeout,
        Net::ReadTimeout
      ].freeze

      def initialize(base_url:, authenticator:, config: nil)
        @config = config
        @max_retries = config&.max_retries || 3
        @retry_base_delay = config&.retry_base_delay || 1.0
        @retry_max_delay = config&.retry_max_delay || 30.0

        @cookie_jar = CookieJar.new
        @request_builder = RequestBuilder.new(
          base_url: base_url,
          authenticator: authenticator,
          cookie_jar: @cookie_jar
        )
        @response_handler = ResponseHandler.new
        @connection_pool = ConnectionPool.new(
          base_url: base_url,
          max_connections: 10,
          read_timeout: config&.read_timeout,
          connect_timeout: config&.connect_timeout
        )
      end

      # Execute HTTP request with automatic retry for transient errors
      # Uses connection pool for thread-safe parallel execution
      def request(method:, path:, body: nil, query_params: nil)
        uri = @request_builder.build_uri(path, query_params)
        attempt = 0

        loop do
          attempt += 1
          request = @request_builder.build_request(method, uri, body)

          DebugLogger.log_request(method, uri, body, request.to_hash)

          begin
            response = execute_request(uri, request)
            DebugLogger.log_response(response)

            # Check if response is retryable before handling
            if @response_handler.retryable?(response) && attempt <= @max_retries
              delay = calculate_retry_delay(attempt, response)
              log_retry(attempt, delay, "HTTP #{response.code}")
              sleep(delay)
              next
            end

            return @response_handler.handle(response)
          rescue *RETRYABLE_EXCEPTIONS => e
            raise Error, "Connection error: #{e.message}" if attempt > @max_retries

            delay = calculate_retry_delay(attempt)
            log_retry(attempt, delay, e.class.name)
            sleep(delay)
          end
        end
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

      def calculate_retry_delay(attempt, response = nil)
        # Use Retry-After header if available (for rate limits)
        if response
          info = @response_handler.extract_rate_limit_info(response)
          return info[:retry_after] if info[:retry_after]&.positive?
        end

        # Exponential backoff with jitter
        base_delay = @retry_base_delay * (2**(attempt - 1))
        jitter = rand * 0.5 * base_delay # Add up to 50% jitter
        delay = base_delay + jitter

        [delay, @retry_max_delay].min
      end

      def log_retry(attempt, delay, reason)
        return unless ENV['SUMO_DEBUG'] || $DEBUG

        warn "[Sumologic::Http::Client] Retry #{attempt}/#{@max_retries} after #{delay.round(2)}s (#{reason})"
      end
    end
  end
end
