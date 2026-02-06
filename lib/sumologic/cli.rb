# frozen_string_literal: true

require 'thor'
require 'json'
require_relative 'cli/commands/search_command'
require_relative 'cli/commands/list_collectors_command'
require_relative 'cli/commands/list_sources_command'
require_relative 'cli/commands/discover_sources_command'

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

    desc 'discover-sources', 'Discover dynamic source names from logs'
    long_desc <<~DESC
      Discover dynamic source names by querying actual log data.
      Useful for CloudWatch/ECS sources that use dynamic _sourceName values.

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
