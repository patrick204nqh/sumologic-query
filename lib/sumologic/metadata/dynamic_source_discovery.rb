# frozen_string_literal: true

require_relative 'loggable'
require_relative 'models'

module Sumologic
  module Metadata
    # Discovers dynamic source names from actual log data via Search API
    # Useful for CloudWatch/ECS sources that use dynamic _sourceName values
    class DynamicSourceDiscovery
      include Loggable

      def initialize(http_client:, search_job:, config: nil)
        @http = http_client
        @search_job = search_job
        @config = config || Configuration.new
      end

      # Discover dynamic source names from logs
      # Returns hash with ALL unique source names found
      #
      # @param from_time [String] Start time (ISO 8601, unix timestamp, or relative)
      # @param to_time [String] End time
      # @param time_zone [String] Time zone (default: UTC)
      # @param filter [String, nil] Optional filter query to scope results
      def discover(from_time:, to_time:, time_zone: 'UTC', filter: nil)
        query = build_query(filter)
        log_info "Discovering dynamic sources with query: #{query}"
        log_info "Time range: #{from_time} to #{to_time} (#{time_zone})"

        # Fetch aggregated records to find all unique sources
        # Internal limit of 10K aggregation records balances performance vs completeness
        records = @search_job.execute_aggregation(
          query: query,
          from_time: from_time,
          to_time: to_time,
          time_zone: time_zone,
          limit: 10_000
        )

        source_models = parse_aggregation_results(records)

        {
          'time_range' => {
            'from' => from_time,
            'to' => to_time,
            'time_zone' => time_zone
          },
          'filter' => filter,
          'total_sources' => source_models.size,
          'sources' => source_models.map(&:to_h)
        }
      rescue StandardError => e
        raise Error, "Failed to discover dynamic sources: #{e.message}"
      end

      private

      # Build aggregation query to discover sources
      def build_query(filter)
        base = filter || '*'
        # Aggregate by _sourceName and _sourceCategory, count messages
        # Sort by count descending to show most active sources first
        # NO limit in query - we want to discover ALL sources
        # The limit parameter controls how many aggregation results we fetch
        "#{base} | count by _sourceName, _sourceCategory | sort by _count desc"
      end

      # Parse aggregation records from search API
      # Returns array of DynamicSourceModel objects
      def parse_aggregation_results(records)
        return [] if records.empty?

        # Debug: Check first record to see what fields are available
        if debug_enabled? && records.first
          first_map = records.first['map'] || {}
          log_info "Sample aggregation record fields: #{first_map.keys.join(', ')}"
          log_info "Sample _count value: #{first_map['_count']}"
        end

        # Use a hash to deduplicate by name+category, keeping highest count
        sources_hash = {}
        skipped_zero_count = 0

        records.each do |record|
          map = record['map'] || {}

          # Skip if no _sourceName (shouldn't happen with count by _sourceName)
          source_name = map['_sourcename']
          next unless source_name

          source_category = map['_sourcecategory']
          # Sumo Logic aggregation returns _count field
          message_count = (map['_count'] || 0).to_i

          # Skip sources with 0 count (shouldn't happen in valid aggregation results)
          if message_count.zero?
            skipped_zero_count += 1
            next
          end

          # Create unique key for deduplication
          key = "#{source_name}||#{source_category}"

          # Keep the entry with highest count (or first if counts are equal)
          next unless !sources_hash[key] || sources_hash[key][:count] < message_count

          sources_hash[key] = {
            name: source_name,
            category: source_category,
            count: message_count
          }
        end

        # Convert hash to model objects
        source_models = sources_hash.values.map do |source_data|
          DynamicSourceModel.new(
            name: source_data[:name],
            category: source_data[:category],
            message_count: source_data[:count]
          )
        end

        # Sort by message count descending
        source_models.sort!

        log_info "Skipped #{skipped_zero_count} sources with zero message count" if skipped_zero_count > 0
        log_info "Discovered #{source_models.size} unique source names (from #{records.size} records)"
        source_models
      end
    end
  end
end
