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

        log_sample_record(records.first) if debug_enabled?

        sources_hash, skipped_count = collect_sources_from_records(records)
        source_models = build_source_models(sources_hash)

        log_discovery_summary(skipped_count, source_models.size, records.size)
        source_models
      end

      # Log sample record for debugging
      def log_sample_record(record)
        return unless record

        first_map = record['map'] || {}
        log_info "Sample aggregation record fields: #{first_map.keys.join(', ')}"
        log_info "Sample _count value: #{first_map['_count']}"
      end

      # Collect unique sources from records, deduplicating by name+category
      def collect_sources_from_records(records)
        sources_hash = {}
        skipped_zero_count = 0

        records.each do |record|
          source_data = extract_source_data(record)
          next unless source_data

          if source_data[:count].zero?
            skipped_zero_count += 1
            next
          end

          update_sources_hash(sources_hash, source_data)
        end

        [sources_hash, skipped_zero_count]
      end

      # Extract source data from a single record
      def extract_source_data(record)
        map = record['map'] || {}
        source_name = map['_sourcename']
        return nil unless source_name

        {
          name: source_name,
          category: map['_sourcecategory'],
          count: (map['_count'] || 0).to_i
        }
      end

      # Update sources hash with new source data (keeping highest count)
      def update_sources_hash(sources_hash, source_data)
        key = "#{source_data[:name]}||#{source_data[:category]}"
        existing = sources_hash[key]

        return if existing && existing[:count] >= source_data[:count]

        sources_hash[key] = source_data
      end

      # Build and sort model objects from source hash
      def build_source_models(sources_hash)
        source_models = sources_hash.values.map do |source_data|
          DynamicSourceModel.new(
            name: source_data[:name],
            category: source_data[:category],
            message_count: source_data[:count]
          )
        end

        source_models.sort
      end

      # Log summary of discovery results
      def log_discovery_summary(skipped_count, discovered_count, total_records)
        log_info "Skipped #{skipped_count} sources with zero message count" if skipped_count.positive?
        log_info "Discovered #{discovered_count} unique source names (from #{total_records} records)"
      end
    end
  end
end
