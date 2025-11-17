# frozen_string_literal: true

module Sumologic
  class CLI < Thor
    module Commands
      # Metadata commands implementation
      # Handles listing collectors and sources
      module Metadata
        def self.included(base)
          base.class_eval do
            desc 'list-collectors', 'List all Sumo Logic collectors'
            long_desc <<~DESC
              List all collectors in your Sumo Logic account.

              Example:
                sumo-query list-collectors --output collectors.json
            DESC
            def list_collectors
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
              if options[:collector_id]
                list_sources_for_collector(client, options[:collector_id])
              else
                list_all_sources(client)
              end
            end
          end
        end

        private

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
      end
    end
  end
end
