# frozen_string_literal: true

require_relative 'collector_source_fetcher'
require_relative 'loggable'

module Sumologic
  module Metadata
    # Handles source metadata operations
    class Source
      include Loggable

      def initialize(http_client:, collector_client:, config: nil)
        @http = http_client
        @collector_client = collector_client
        @config = config
        @fetcher = CollectorSourceFetcher.new(config: @config)
      end

      # List sources for a specific collector
      # Returns array of source objects with metadata
      def list(collector_id:)
        data = @http.request(
          method: :get,
          path: "/collectors/#{collector_id}/sources"
        )

        sources = data['sources'] || []
        log_info "Found #{sources.size} sources for collector #{collector_id}"
        sources
      rescue StandardError => e
        raise Error, "Failed to list sources for collector #{collector_id}: #{e.message}"
      end

      # List all sources from all collectors with optional filtering
      # Returns array of hashes with collector info and their sources
      # Uses parallel fetching with thread pool for better performance
      #
      # @param collector [String, nil] Filter collectors by name (case-insensitive substring)
      # @param name [String, nil] Filter sources by name (case-insensitive substring)
      # @param category [String, nil] Filter sources by category (case-insensitive substring)
      # @param limit [Integer, nil] Maximum total sources to return
      def list_all(collector: nil, name: nil, category: nil, limit: nil)
        collectors = @collector_client.list
        active_collectors = collectors.select { |c| c['alive'] }
        active_collectors = filter_collectors(active_collectors, collector) if collector

        log_info "Fetching sources for #{active_collectors.size} active collectors in parallel..."

        result = @fetcher.fetch_all(active_collectors) do |c|
          fetch_collector_sources(c)
        end

        result = filter_sources(result, name: name, category: category)
        result = apply_source_limit(result, limit) if limit

        log_info "Total: #{result.size} collectors with sources"
        result
      rescue StandardError => e
        raise Error, "Failed to list all sources: #{e.message}"
      end

      private

      def filter_collectors(collectors, pattern)
        pattern = pattern.downcase
        collectors.select { |c| (c['name'] || '').downcase.include?(pattern) }
      end

      def filter_sources(result, name:, category:)
        matcher = source_matcher(name&.downcase, category&.downcase)
        result.filter_map do |entry|
          filtered = entry['sources'].select(&matcher)
          { 'collector' => entry['collector'], 'sources' => filtered } unless filtered.empty?
        end
      end

      def source_matcher(name_pattern, cat_pattern)
        lambda do |s|
          (!name_pattern || (s['name'] || '').downcase.include?(name_pattern)) &&
            (!cat_pattern || (s['category'] || '').downcase.include?(cat_pattern))
        end
      end

      def apply_source_limit(result, limit)
        remaining = limit
        result.each_with_object([]) do |entry, acc|
          break acc if remaining <= 0

          sources = entry['sources'].take(remaining)
          acc << { 'collector' => entry['collector'], 'sources' => sources }
          remaining -= sources.size
        end
      end

      # Fetch sources for a single collector
      # @return [Hash] collector and sources data
      def fetch_collector_sources(collector)
        collector_id = collector['id']
        collector_name = collector['name']

        log_info "Fetching sources for collector: #{collector_name} (#{collector_id})"
        sources = list(collector_id: collector_id)

        {
          'collector' => collector,
          'sources' => sources
        }
      rescue StandardError => e
        log_error "Failed to fetch sources for collector #{collector_name}: #{e.message}"
        nil
      end
    end
  end
end
