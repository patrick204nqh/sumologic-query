# frozen_string_literal: true

module Sumologic
  # Facade for Sumo Logic API operations
  # Coordinates HTTP, Search, and Metadata components
  class Client
    attr_reader :config

    def initialize(config = nil) # rubocop:disable Metrics/MethodLength
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
      @source_metadata_discovery = Metadata::SourceMetadataDiscovery.new(
        http_client: @http,
        search_job: @search,
        config: @config
      )
      @monitor = Metadata::Monitor.new(http_client: @http)
      @folder = Metadata::Folder.new(http_client: @http_v2) # Uses v2 API
      @dashboard = Metadata::Dashboard.new(http_client: @http_v2)
      @health_event = Metadata::HealthEvent.new(http_client: @http)
      @field = Metadata::Field.new(http_client: @http)
      @lookup_table = Metadata::LookupTable.new(http_client: @http)
      @app = Metadata::App.new(http_client: @http)
      @content = Metadata::Content.new(http_client: @http_v2) # Uses v2 API
    end

    # Search logs with query
    #
    # @param query [String] Sumo Logic query
    # @param from_time [String] Start time (ISO 8601, unix timestamp, or relative)
    # @param to_time [String] End time
    # @param time_zone [String] Time zone (default: UTC)
    # @param limit [Integer, nil] Maximum number of messages to return (stops fetching after limit)
    # @return [Array<Hash>] Array of message hashes
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
    #
    # @param query [String] Sumo Logic aggregation query (must include count, sum, avg, etc.)
    # @param from_time [String] Start time (ISO 8601, unix timestamp, or relative)
    # @param to_time [String] End time
    # @param time_zone [String] Time zone (default: UTC)
    # @param limit [Integer, nil] Maximum number of records to return
    # @return [Array<Hash>] Array of aggregation record hashes
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
    #
    # @return [Array<Hash>] Array of collector hashes
    def list_collectors
      @collector.list
    end

    # List sources for a specific collector
    #
    # @param collector_id [String] The collector ID
    # @return [Array<Hash>] Array of source hashes
    def list_sources(collector_id:)
      @source.list(collector_id: collector_id)
    end

    # List all sources from all collectors
    #
    # @return [Array<Hash>] Array of { 'collector' => Hash, 'sources' => Array<Hash> }
    def list_all_sources
      @source.list_all
    end

    # Discover source metadata from actual log data
    # Useful for CloudWatch/ECS sources with dynamic _sourceName values
    #
    # @param from_time [String] Start time (ISO 8601, unix timestamp, or relative)
    # @param to_time [String] End time
    # @param time_zone [String] Time zone (default: UTC)
    # @param filter [String, nil] Optional filter query to scope results
    # @return [Hash] Discovery results with source metadata
    def discover_source_metadata(from_time:, to_time:, time_zone: 'UTC', filter: nil)
      @source_metadata_discovery.discover(
        from_time: from_time,
        to_time: to_time,
        time_zone: time_zone,
        filter: filter
      )
    end

    # ============================================================
    # Monitors API (uses search endpoint)
    # ============================================================

    # List monitors with optional status and query filters
    #
    # @param query [String, nil] Search query to filter by name/description
    # @param status [String, nil] Filter by status (Normal, Critical, Warning, MissingData, Disabled, AllTriggered)
    # @param limit [Integer] Maximum monitors to return (default: 100)
    # @return [Array<Hash>] Array of monitor hashes
    def list_monitors(query: nil, status: nil, limit: 100)
      @monitor.list(query: query, status: status, limit: limit)
    end

    # Get a specific monitor by ID
    #
    # @param monitor_id [String] The monitor ID
    # @return [Hash] Monitor details
    def get_monitor(monitor_id:)
      @monitor.get(monitor_id)
    end

    # ============================================================
    # Folders API (Content Library)
    # ============================================================

    # Get the personal folder for current user
    #
    # @return [Hash] Folder hash with children
    def personal_folder
      @folder.personal
    end

    # Get a specific folder by ID
    #
    # @param folder_id [String] The folder ID
    # @return [Hash] Folder hash with children
    def get_folder(folder_id:)
      @folder.get(folder_id)
    end

    # Get folder tree starting from a folder
    #
    # @param folder_id [String, nil] Starting folder ID (nil for personal)
    # @param max_depth [Integer] Maximum recursion depth (default: 3)
    # @return [Hash] Folder tree with nested children
    def folder_tree(folder_id: nil, max_depth: 3)
      @folder.tree(folder_id: folder_id, max_depth: max_depth)
    end

    # ============================================================
    # Dashboards API
    # ============================================================

    # List all dashboards
    #
    # @param limit [Integer] Maximum dashboards to return (default: 100)
    # @return [Array<Hash>] Array of dashboard hashes
    def list_dashboards(limit: 100)
      @dashboard.list(limit: limit)
    end

    # Get a specific dashboard by ID
    #
    # @param dashboard_id [String] The dashboard ID
    # @return [Hash] Dashboard hash including panels
    def get_dashboard(dashboard_id:)
      @dashboard.get(dashboard_id)
    end

    # Search dashboards by title or description
    #
    # @param query [String] Search query
    # @param limit [Integer] Maximum results
    # @return [Array<Hash>] Array of matching dashboard hashes
    def search_dashboards(query:, limit: 100)
      @dashboard.search(query: query, limit: limit)
    end

    # ============================================================
    # Health Events API
    # ============================================================

    # List health events for collectors, sources, and ingest budgets
    #
    # @param limit [Integer] Maximum events to return (default: 100)
    # @return [Array<Hash>] Array of health event hashes
    def list_health_events(limit: 100)
      @health_event.list(limit: limit)
    end

    # ============================================================
    # Fields API
    # ============================================================

    # List custom fields
    #
    # @return [Array<Hash>] Array of field hashes
    def list_fields
      @field.list
    end

    # List built-in fields
    #
    # @return [Array<Hash>] Array of built-in field hashes
    def list_builtin_fields
      @field.list_builtin
    end

    # ============================================================
    # Lookup Tables API
    # ============================================================

    # Get a specific lookup table by ID
    #
    # @param lookup_id [String] The lookup table ID
    # @return [Hash] Lookup table details
    def get_lookup(lookup_id:)
      @lookup_table.get(lookup_id)
    end

    # ============================================================
    # Apps API (Catalog)
    # ============================================================

    # List available apps from the Sumo Logic app catalog
    #
    # @return [Array<Hash>] Array of app hashes
    def list_apps
      @app.list
    end

    # ============================================================
    # Content Library API (path-based)
    # ============================================================

    # Get a content item by its library path
    #
    # @param path [String] Content library path (e.g., '/Library/Users/me/My Search')
    # @return [Hash] Content item details
    def get_content(path:)
      @content.get_by_path(path)
    end

    # Export a content item as JSON
    # Handles async job lifecycle: start, poll, fetch result
    #
    # @param content_id [String] The content item ID to export
    # @return [Hash] Exported content definition
    def export_content(content_id:)
      @content.export(content_id)
    end
  end
end
