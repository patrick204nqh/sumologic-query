# frozen_string_literal: true

module Sumologic
  module Http
    # Thread-safe connection pool for HTTP clients
    # Allows multiple threads to have their own connections
    class ConnectionPool
      READ_TIMEOUT = 60
      OPEN_TIMEOUT = 10

      def initialize(base_url:, max_connections: 10)
        @base_url = base_url
        @max_connections = max_connections
        @pool = []
        @mutex = Mutex.new
      end

      # Get a connection from the pool (or create new one)
      def with_connection(uri)
        connection = acquire_connection(uri)
        yield connection
      ensure
        release_connection(connection) if connection
      end

      # Close all connections in the pool
      def close_all
        @mutex.synchronize do
          @pool.each do |conn|
            conn[:http].finish if conn[:http].started?
          rescue StandardError => e
            warn "Error closing connection: #{e.message}"
          end
          @pool.clear
        end
      end

      private

      def acquire_connection(uri)
        @mutex.synchronize do
          # Try to find an available connection for this host
          connection = find_available_connection(uri)
          return connection[:http] if connection

          # Create new connection if under limit
          if @pool.size < @max_connections
            http = create_connection(uri)
            @pool << { http: http, in_use: true, host: uri.host, port: uri.port }
            return http
          end

          # Wait and retry if pool is full
          nil
        end || create_temporary_connection(uri)
      end

      def find_available_connection(uri)
        connection = @pool.find do |conn|
          !conn[:in_use] &&
            conn[:host] == uri.host &&
            conn[:port] == uri.port &&
            conn[:http].started?
        rescue StandardError
          # Connection is invalid
          @pool.delete(conn)
          nil
        end

        connection[:in_use] = true if connection
        connection
      end

      def release_connection(http)
        @mutex.synchronize do
          connection = @pool.find { |conn| conn[:http] == http }
          connection[:in_use] = false if connection
        end
      end

      def create_connection(uri)
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true
        http.read_timeout = READ_TIMEOUT
        http.open_timeout = OPEN_TIMEOUT
        http.keep_alive_timeout = 30
        http.start
        http
      end

      def create_temporary_connection(uri)
        # Fallback: create a temporary connection if pool is exhausted
        create_connection(uri)
      end
    end
  end
end
