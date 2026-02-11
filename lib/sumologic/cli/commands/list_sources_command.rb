# frozen_string_literal: true

require_relative 'base_command'

module Sumologic
  class CLI < Thor
    module Commands
      # Handles the list-sources command execution
      class ListSourcesCommand < BaseCommand
        def execute
          if options[:collector_id]
            list_sources_for_collector
          else
            list_all_sources
          end
        end

        private

        def list_sources_for_collector
          warn "Fetching sources for collector: #{options[:collector_id]}"
          sources = client.list_sources(collector_id: options[:collector_id])

          output_json(
            collector_id: options[:collector_id],
            total: sources.size,
            sources: sources
          )
        end

        def list_all_sources
          warn 'Fetching all sources from all collectors...'
          warn 'This may take a minute...'

          all_sources = client.list_all_sources

          output_json(
            total_collectors: all_sources.size,
            total_sources: all_sources.sum { |c| c['sources'].size },
            data: all_sources
          )
        end
      end
    end
  end
end
