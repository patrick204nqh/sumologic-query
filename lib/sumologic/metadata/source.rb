# frozen_string_literal: true

require_relative 'collector_source_fetcher'

module Sumologic
  module Metadata
    # Handles source metadata operations
    class Source
      def initialize(http_client:, collector_client:)
        @http = http_client
        @collector_client = collector_client
        @fetcher = CollectorSourceFetcher.new
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

      # List all sources from all collectors
      # Returns array of hashes with collector info and their sources
      # Uses parallel fetching with thread pool for better performance
      def list_all
        collectors = @collector_client.list
        active_collectors = collectors.select { |c| c['alive'] }

        log_info "Fetching sources for #{active_collectors.size} active collectors in parallel..."

        result = @fetcher.fetch_all(active_collectors) do |collector|
          fetch_collector_sources(collector)
        end

        log_info "Total: #{result.size} collectors with sources"
        result
      rescue StandardError => e
        raise Error, "Failed to list all sources: #{e.message}"
      end

      private

      # Fetch sources for a single collector
      def fetch_collector_sources(collector)
        collector_id = collector['id']
        collector_name = collector['name']

        log_info "Fetching sources for collector: #{collector_name} (#{collector_id})"
        sources = list(collector_id: collector_id)

        {
          'collector' => {
            'id' => collector_id,
            'name' => collector_name,
            'collectorType' => collector['collectorType']
          },
          'sources' => sources
        }
      rescue StandardError => e
        log_error "Failed to fetch sources for collector #{collector_name}: #{e.message}"
        nil
      end

      def log_info(message)
        warn "[Sumologic::Metadata::Source] #{message}" if ENV['SUMO_DEBUG'] || $DEBUG
      end

      def log_error(message)
        warn "[Sumologic::Metadata::Source ERROR] #{message}"
      end
    end
  end
end
