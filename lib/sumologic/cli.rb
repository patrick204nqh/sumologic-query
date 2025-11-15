# frozen_string_literal: true

require 'thor'
require 'json'

module Sumologic
  # Thor-based CLI for Sumo Logic query tool
  class CLI < Thor
    class_option :debug, type: :boolean, aliases: '-d', desc: 'Enable debug output'
    class_option :output, type: :string, aliases: '-o', desc: 'Output file (default: stdout)'

    def self.exit_on_failure?
      true
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
    DESC
    option :query, type: :string, required: true, aliases: '-q', desc: 'Search query'
    option :from, type: :string, required: true, aliases: '-f', desc: 'Start time (ISO 8601)'
    option :to, type: :string, required: true, aliases: '-t', desc: 'End time (ISO 8601)'
    option :time_zone, type: :string, default: 'UTC', aliases: '-z', desc: 'Time zone'
    option :limit, type: :numeric, aliases: '-l', desc: 'Maximum messages to return'
    def search
      $DEBUG = true if options[:debug]

      client = create_client

      log_search_info
      results = execute_search(client)

      warn '=' * 60
      warn "Results: #{results.size} messages"
      warn '=' * 60
      $stderr.puts

      output_search_results(results)
    end

    desc 'list-collectors', 'List all Sumo Logic collectors'
    long_desc <<~DESC
      List all collectors in your Sumo Logic account.

      Example:
        sumo-query list-collectors --output collectors.json
    DESC
    def list_collectors
      $DEBUG = true if options[:debug]

      client = create_client

      warn 'Fetching collectors...'
      collectors = client.list_collectors

      output_json(
        total: collectors.size,
        collectors: collectors.map { |c| format_collector(c) }
      )
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
      $DEBUG = true if options[:debug]

      client = create_client

      if options[:collector_id]
        list_sources_for_collector(client, options[:collector_id])
      else
        list_all_sources(client)
      end
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

    def list_sources_for_collector(client, collector_id)
      warn "Fetching sources for collector: #{collector_id}"
      sources = client.list_sources(collector_id: collector_id)

      output_json(
        collector_id: collector_id,
        total: sources.size,
        sources: sources.map { |s| format_source(s) }
      )
    end

    def list_all_sources(client)
      warn 'Fetching all sources from all collectors...'
      warn 'This may take a minute...'

      all_sources = client.list_all_sources

      output_json(
        total_collectors: all_sources.size,
        total_sources: all_sources.sum { |c| c['sources'].size },
        data: all_sources.map do |item|
          {
            collector: item['collector'],
            sources: item['sources'].map { |s| format_source(s) }
          }
        end
      )
    end

    def format_collector(collector)
      {
        id: collector['id'],
        name: collector['name'],
        collectorType: collector['collectorType'],
        alive: collector['alive'],
        category: collector['category']
      }
    end

    def format_source(source)
      {
        id: source['id'],
        name: source['name'],
        category: source['category'],
        sourceType: source['sourceType'],
        alive: source['alive']
      }
    end

    def output_json(data)
      json_output = JSON.pretty_generate(data)

      if options[:output]
        File.write(options[:output], json_output)
        warn "\nResults saved to: #{options[:output]}"
      else
        puts json_output
      end
    end

    def error(message)
      warn message
    end

    def log_search_info
      warn '=' * 60
      warn 'Sumo Logic Search Query'
      warn '=' * 60
      warn "Time Range: #{options[:from]} to #{options[:to]}"
      warn "Query: #{options[:query]}"
      warn "Limit: #{options[:limit] || 'unlimited'}"
      warn '-' * 60
      warn 'Creating search job...'
      $stderr.puts
    end

    def execute_search(client)
      client.search(
        query: options[:query],
        from_time: options[:from],
        to_time: options[:to],
        time_zone: options[:time_zone],
        limit: options[:limit]
      )
    end

    def output_search_results(results)
      output_json(
        query: options[:query],
        from: options[:from],
        to: options[:to],
        time_zone: options[:time_zone],
        message_count: results.size,
        messages: results
      )
    end
  end
end
