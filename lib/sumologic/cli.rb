# frozen_string_literal: true

require 'thor'
require 'json'
require_relative 'cli/commands/search_command'
require_relative 'cli/commands/list_collectors_command'
require_relative 'cli/commands/list_sources_command'

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

      Examples:
        # Error timeline with 5-minute buckets
        sumo-query search --query 'error | timeslice 5m | count' \\
          --from '2025-11-13T14:00:00' --to '2025-11-13T15:00:00'

        # Search for specific text
        sumo-query search --query '"connection timeout"' \\
          --from '2025-11-13T14:00:00' --to '2025-11-13T15:00:00' \\
          --limit 100

        # Interactive mode with FZF
        sumo-query search --query 'error' \\
          --from '2025-11-13T14:00:00' --to '2025-11-13T15:00:00' \\
          --interactive
    DESC
    option :query, type: :string, required: true, aliases: '-q', desc: 'Search query'
    option :from, type: :string, required: true, aliases: '-f', desc: 'Start time (ISO 8601)'
    option :to, type: :string, required: true, aliases: '-t', desc: 'End time (ISO 8601)'
    option :time_zone, type: :string, default: 'UTC', aliases: '-z', desc: 'Time zone'
    option :limit, type: :numeric, aliases: '-l', desc: 'Maximum messages to return'
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
