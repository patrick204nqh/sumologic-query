# frozen_string_literal: true

module Sumologic
  # Facade for Sumo Logic API operations
  # Coordinates HTTP, Search, and Metadata components
  class Client
    attr_reader :config

    def initialize(config = nil)
      @config = config || Configuration.new
      @config.validate!

      # Initialize HTTP layer (v1 API)
      authenticator = Http::Authenticator.new(
        access_id: @config.access_id,
        access_key: @config.access_key
      )
      @http = Http::Client.new(
        base_url: @config.base_url,
        authenticator: authenticator,
        config: @config
      )

      # Initialize HTTP layer for v2 API (Content Library)
      @http_v2 = Http::Client.new(
        base_url: @config.base_url_v2,
        authenticator: authenticator,
        config: @config
      )

      # Initialize domain components
      @search = Search::Job.new(http_client: @http, config: @config)
      @collector = Metadata::Collector.new(http_client: @http)
      @source = Metadata::Source.new(http_client: @http, collector_client: @collector, config: @config)
      @dynamic_source_discovery = Metadata::DynamicSourceDiscovery.new(
        http_client: @http,
        search_job: @search,
        config: @config
      )
      @monitor = Metadata::Monitor.new(http_client: @http)
      @folder = Metadata::Folder.new(http_client: @http_v2) # Uses v2 API
      @dashboard = Metadata::Dashboard.new(http_client: @http)
    end

    # Search logs with query
    # Returns array of messages
    #
    # @param query [String] Sumo Logic query
    # @param from_time [String] Start time (ISO 8601, unix timestamp, or relative)
    # @param to_time [String] End time
    # @param time_zone [String] Time zone (default: UTC)
    # @param limit [Integer, nil] Maximum number of messages to return (stops fetching after limit)
    def search(query:, from_time:, to_time:, time_zone: 'UTC', limit: nil)
      @search.execute(
        query: query,
        from_time: from_time,
        to_time: to_time,
        time_zone: time_zone,
        limit: limit
      )
    end

    # Search with aggregation query (count by, group by, etc.)
    # Returns array of aggregation records instead of raw messages
    #
    # @param query [String] Sumo Logic aggregation query (must include count, sum, avg, etc.)
    # @param from_time [String] Start time (ISO 8601, unix timestamp, or relative)
    # @param to_time [String] End time
    # @param time_zone [String] Time zone (default: UTC)
    # @param limit [Integer, nil] Maximum number of records to return
    def search_aggregation(query:, from_time:, to_time:, time_zone: 'UTC', limit: nil)
      @search.execute_aggregation(
        query: query,
        from_time: from_time,
        to_time: to_time,
        time_zone: time_zone,
        limit: limit
      )
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

    # Discover dynamic source names from actual log data
    # Useful for CloudWatch/ECS sources with dynamic _sourceName values
    # Returns hash with ALL unique source names found, with message counts
    #
    # @param from_time [String] Start time (ISO 8601, unix timestamp, or relative)
    # @param to_time [String] End time
    # @param time_zone [String] Time zone (default: UTC)
    # @param filter [String, nil] Optional filter query to scope results
    def discover_dynamic_sources(from_time:, to_time:, time_zone: 'UTC', filter: nil)
      @dynamic_source_discovery.discover(
        from_time: from_time,
        to_time: to_time,
        time_zone: time_zone,
        filter: filter
      )
    end

    # ============================================================
    # Monitors API
    # ============================================================

    # List all monitors
    # Returns array of monitor objects
    #
    # @param limit [Integer] Maximum monitors to return (default: 100)
    def list_monitors(limit: 100)
      @monitor.list(limit: limit)
    end

    # Get a specific monitor by ID
    # Returns full monitor details
    #
    # @param monitor_id [String] The monitor ID
    def get_monitor(monitor_id:)
      @monitor.get(monitor_id)
    end

    # Get the root monitors folder
    # Returns folder with monitors hierarchy
    def monitors_root
      @monitor.root
    end

    # Search monitors by name or description
    #
    # @param query [String] Search query
    # @param limit [Integer] Maximum results
    def search_monitors(query:, limit: 100)
      @monitor.search(query: query, limit: limit)
    end

    # ============================================================
    # Folders API (Content Library)
    # ============================================================

    # Get the personal folder for current user
    # Returns folder with children
    def personal_folder
      @folder.personal
    end

    # Get the global (admin) folder
    # Requires admin privileges
    def global_folder
      @folder.global
    end

    # Get a specific folder by ID
    # Returns folder details with children
    #
    # @param folder_id [String] The folder ID
    def get_folder(folder_id:)
      @folder.get(folder_id)
    end

    # Get folder tree starting from a folder
    # Recursively fetches children up to max_depth
    #
    # @param folder_id [String, nil] Starting folder ID (nil for personal)
    # @param max_depth [Integer] Maximum recursion depth (default: 3)
    def folder_tree(folder_id: nil, max_depth: 3)
      @folder.tree(folder_id: folder_id, max_depth: max_depth)
    end

    # ============================================================
    # Dashboards API
    # ============================================================

    # List all dashboards
    # Returns array of dashboard objects
    #
    # @param limit [Integer] Maximum dashboards to return (default: 100)
    def list_dashboards(limit: 100)
      @dashboard.list(limit: limit)
    end

    # Get a specific dashboard by ID
    # Returns full dashboard details including panels
    #
    # @param dashboard_id [String] The dashboard ID
    def get_dashboard(dashboard_id:)
      @dashboard.get(dashboard_id)
    end

    # Search dashboards by title or description
    #
    # @param query [String] Search query
    # @param limit [Integer] Maximum results
    def search_dashboards(query:, limit: 100)
      @dashboard.search(query: query, limit: limit)
    end
  end
end
