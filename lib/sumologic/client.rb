# frozen_string_literal: true

module Sumologic
  # Facade for Sumo Logic API operations
  # Coordinates HTTP, Search, and Metadata components
  class Client
    attr_reader :config

    def initialize(config = nil)
      @config = config || Configuration.new
      @config.validate!

      # Initialize HTTP layer
      authenticator = Http::Authenticator.new(
        access_id: @config.access_id,
        access_key: @config.access_key
      )
      @http = Http::Client.new(
        base_url: @config.base_url,
        authenticator: authenticator
      )

      # Initialize domain components
      @search = Search::Job.new(http_client: @http, config: @config)
      @collector = Metadata::Collector.new(http_client: @http)
      @source = Metadata::Source.new(http_client: @http, collector_client: @collector)
    end

    # Search logs with query
    # Returns array of messages
    def search(query:, from_time:, to_time:, time_zone: 'UTC', limit: nil)
      @search.execute(
        query: query,
        from_time: from_time,
        to_time: to_time,
        time_zone: time_zone,
        limit: limit
      )
    end

    # Search logs with streaming interface
    # Returns an Enumerator that yields messages one at a time
    # More memory efficient for large result sets
    #
    # Example:
    #   client.search_stream(query: 'error', from_time: ..., to_time: ...).each do |message|
    #     puts message['map']['message']
    #   end
    def search_stream(query:, from_time:, to_time:, time_zone: 'UTC', limit: nil)
      job_id = @search.create_and_wait(
        query: query,
        from_time: from_time,
        to_time: to_time,
        time_zone: time_zone
      )

      @search.stream_messages(job_id, limit: limit)
    end

    # List all collectors
    # Returns array of collector objects
    def list_collectors
      @collector.list
    end

    # List sources for a specific collector
    # Returns array of source objects
    def list_sources(collector_id:)
      @source.list(collector_id: collector_id)
    end

    # List all sources from all collectors
    # Returns array of hashes with collector and sources
    def list_all_sources
      @source.list_all
    end
  end
end
