# frozen_string_literal: true

require 'thor'
require 'json'
require_relative 'cli/commands/search_command'
require_relative 'cli/commands/list_collectors_command'
require_relative 'cli/commands/list_sources_command'
require_relative 'cli/commands/discover_sources_command'
require_relative 'cli/commands/list_monitors_command'
require_relative 'cli/commands/get_monitor_command'
require_relative 'cli/commands/list_folders_command'
require_relative 'cli/commands/list_dashboards_command'
require_relative 'cli/commands/get_dashboard_command'

module Sumologic
  # Thor-based CLI for Sumo Logic query tool
  # Delegates commands to specialized command classes
  class CLI < Thor
    class_option :debug, type: :boolean, aliases: '-d', desc: 'Enable debug output'
    class_option :output, type: :string, aliases: '-o', desc: 'Output file (default: stdout)'

    def self.exit_on_failure?
      true
    end

    def initialize(*args)
      super
      $DEBUG = true if options[:debug]
    end

    desc 'search', 'Search Sumo Logic logs'
    long_desc <<~DESC
      Search Sumo Logic logs using a query string.

      Time Formats:
        --from and --to support multiple formats:
        • 'now' - current time
        • Relative: '-30s', '-5m', '-2h', '-7d', '-1w', '-1M' (sec/min/hour/day/week/month)
        • Unix timestamp: '1700000000' (seconds since epoch)
        • ISO 8601: '2025-11-13T14:00:00'

      Aggregation Mode (--aggregate):
        Use --aggregate (-a) for queries with count, sum, avg, group by, etc.
        Returns aggregation records instead of raw log messages.

      Examples:
        # Last 30 minutes
        sumo-query search --query 'error' --from '-30m' --to 'now'

        # Last hour with ISO format
        sumo-query search --query 'error | timeslice 5m | count' \\
          --from '2025-11-13T14:00:00' --to '2025-11-13T15:00:00'

        # Last 7 days
        sumo-query search --query '"connection timeout"' \\
          --from '-7d' --to 'now' --limit 100

        # Using Unix timestamps
        sumo-query search --query 'error' \\
          --from '1700000000' --to '1700003600'

        # Interactive mode with FZF
        sumo-query search --query 'error' \\
          --from '-1h' --to 'now' --interactive

        # Aggregation query (count by source)
        sumo-query search --query '* | count by _sourceCategory' \\
          --from '-1h' --to 'now' --aggregate

        # Top errors by count
        sumo-query search --query 'error | count by _sourceHost | top 10' \\
          --from '-24h' --to 'now' --aggregate
    DESC
    option :query, type: :string, required: true, aliases: '-q', desc: 'Search query'
    option :from, type: :string, required: true, aliases: '-f', desc: 'Start time (now, -30m, unix timestamp, ISO 8601)'
    option :to, type: :string, required: true, aliases: '-t', desc: 'End time (now, -30m, unix timestamp, ISO 8601)'
    option :time_zone, type: :string, default: 'UTC', aliases: '-z',
                       desc: 'Time zone (UTC, EST, AEST, +00:00, America/New_York, Australia/Sydney)'
    option :limit, type: :numeric, aliases: '-l', desc: 'Maximum messages to return'
    option :aggregate, type: :boolean, aliases: '-a', desc: 'Return aggregation records (for count/group by queries)'
    option :interactive, type: :boolean, aliases: '-i', desc: 'Launch interactive browser (requires fzf)'
    def search
      Commands::SearchCommand.new(options, create_client).execute
    end

    desc 'list-collectors', 'List all Sumo Logic collectors'
    long_desc <<~DESC
      List all collectors in your Sumo Logic account.

      Example:
        sumo-query list-collectors --output collectors.json
    DESC
    def list_collectors
      Commands::ListCollectorsCommand.new(options, create_client).execute
    end

    desc 'list-sources', 'List sources from collectors'
    long_desc <<~DESC
      List all sources from all collectors, or sources from a specific collector.

      Examples:
        # List all sources
        sumo-query list-sources

        # List sources for specific collector
        sumo-query list-sources --collector-id 12345
    DESC
    option :collector_id, type: :string, desc: 'Collector ID to list sources for'
    def list_sources
      Commands::ListSourcesCommand.new(options, create_client).execute
    end

    desc 'discover-sources', 'Discover source names from log data using search aggregation'
    long_desc <<~DESC
      Discovers source names from actual log data using search aggregation.
      Useful for CloudWatch/ECS/Lambda sources with dynamic _sourceName values
      that are not visible in the Collectors API.

      Note: This is not an official Sumo Logic API. It runs the search query:
        * | count by _sourceName, _sourceCategory | sort by _count desc
      This is a well-known technique in the Sumo Logic community to discover
      runtime sources, complementing the static source configuration from
      the Collectors API (list-sources).

      Time Formats:
        --from and --to support multiple formats:
        • 'now' - current time
        • Relative: '-30s', '-5m', '-2h', '-7d', '-1w', '-1M' (sec/min/hour/day/week/month)
        • Unix timestamp: '1700000000' (seconds since epoch)
        • ISO 8601: '2025-11-13T14:00:00'

      Examples:
        # Discover all sources from last 24 hours (default)
        sumo-query discover-sources

        # Discover sources from last 7 days
        sumo-query discover-sources --from '-7d' --to 'now'

        # Filter by source category (ECS only)
        sumo-query discover-sources --filter '_sourceCategory=*ecs*'

        # Discover CloudWatch sources
        sumo-query discover-sources --filter '_sourceCategory=*cloudwatch*'

        # Save to file
        sumo-query discover-sources --output discovered-sources.json
    DESC
    option :from, type: :string, default: '-24h', aliases: '-f',
                  desc: 'Start time (default: -24h)'
    option :to, type: :string, default: 'now', aliases: '-t',
                desc: 'End time (default: now)'
    option :time_zone, type: :string, default: 'UTC', aliases: '-z',
                       desc: 'Time zone (UTC, EST, AEST, +00:00, America/New_York, Australia/Sydney)'
    option :filter, type: :string, desc: 'Optional filter query (e.g., _sourceCategory=*ecs*)'
    def discover_sources
      Commands::DiscoverSourcesCommand.new(options, create_client).execute
    end

    # ============================================================
    # Monitors Commands
    # ============================================================

    desc 'list-monitors', 'List all monitors (alerts)'
    long_desc <<~DESC
      List all monitors in your Sumo Logic account.
      Monitors are alerting rules that trigger based on log queries.

      Examples:
        # List all monitors
        sumo-query list-monitors

        # List monitors with limit
        sumo-query list-monitors --limit 50

        # Save to file
        sumo-query list-monitors --output monitors.json
    DESC
    option :limit, type: :numeric, aliases: '-l', default: 100, desc: 'Maximum monitors to return'
    def list_monitors
      Commands::ListMonitorsCommand.new(options, create_client).execute
    end

    desc 'get-monitor', 'Get a specific monitor by ID'
    long_desc <<~DESC
      Get detailed information about a specific monitor.

      Example:
        sumo-query get-monitor --monitor-id 0000000000123456
    DESC
    option :monitor_id, type: :string, required: true, desc: 'Monitor ID'
    # rubocop:disable Naming/AccessorMethodName -- Thor CLI command, not a getter
    def get_monitor
      Commands::GetMonitorCommand.new(options, create_client).execute
    end
    # rubocop:enable Naming/AccessorMethodName

    # ============================================================
    # Folders Commands (Content Library)
    # ============================================================

    desc 'list-folders', 'List folders in content library'
    long_desc <<~DESC
      List folders in the Sumo Logic content library.
      By default, shows your personal folder.

      Examples:
        # List personal folder contents
        sumo-query list-folders

        # List specific folder
        sumo-query list-folders --folder-id 0000000000123456

        # Get folder tree (recursive)
        sumo-query list-folders --tree --depth 3

        # Save to file
        sumo-query list-folders --output folders.json
    DESC
    option :folder_id, type: :string, desc: 'Folder ID to list (default: personal folder)'
    option :tree, type: :boolean, desc: 'Fetch recursive tree structure'
    option :depth, type: :numeric, default: 3, desc: 'Maximum tree depth (default: 3)'
    def list_folders
      Commands::ListFoldersCommand.new(options, create_client).execute
    end

    # ============================================================
    # Dashboards Commands
    # ============================================================

    desc 'list-dashboards', 'List all dashboards'
    long_desc <<~DESC
      List all dashboards in your Sumo Logic account.

      Examples:
        # List all dashboards
        sumo-query list-dashboards

        # List dashboards with limit
        sumo-query list-dashboards --limit 50

        # Save to file
        sumo-query list-dashboards --output dashboards.json
    DESC
    option :limit, type: :numeric, aliases: '-l', default: 100, desc: 'Maximum dashboards to return'
    def list_dashboards
      Commands::ListDashboardsCommand.new(options, create_client).execute
    end

    desc 'get-dashboard', 'Get a specific dashboard by ID'
    long_desc <<~DESC
      Get detailed information about a specific dashboard including panels.

      Example:
        sumo-query get-dashboard --dashboard-id 0000000000123456
    DESC
    option :dashboard_id, type: :string, required: true, desc: 'Dashboard ID'
    # rubocop:disable Naming/AccessorMethodName -- Thor CLI command, not a getter
    def get_dashboard
      Commands::GetDashboardCommand.new(options, create_client).execute
    end
    # rubocop:enable Naming/AccessorMethodName

    # ============================================================
    # Utility Commands
    # ============================================================

    desc 'version', 'Show version information'
    def version
      puts "sumo-query version #{Sumologic::VERSION}"
    end
    map %w[-v --version] => :version

    default_task :search

    private

    def create_client
      Client.new
    rescue AuthenticationError => e
      error "Authentication Error: #{e.message}"
      error "\nPlease set environment variables:"
      error "  export SUMO_ACCESS_ID='your_access_id'"
      error "  export SUMO_ACCESS_KEY='your_access_key'"
      error "  export SUMO_DEPLOYMENT='us2'  # Optional, defaults to us2"
      exit 1
    rescue Error => e
      error "Error: #{e.message}"
      exit 1
    end

    def error(message)
      warn message
    end
  end
end
