# frozen_string_literal: true

require_relative 'base_command'
require_relative '../../utils/time_parser'

module Sumologic
  class CLI < Thor
    module Commands
      # Handles the discover-source-metadata command execution
      class DiscoverSourceMetadataCommand < BaseCommand
        def execute
          parse_time_options
          log_discovery_info
          results = perform_discovery

          output_json(results)
        end

        private

        def parse_time_options
          # Parse time formats and store both original and parsed values
          @original_from = options[:from]
          @original_to = options[:to]
          @parsed_from = Utils::TimeParser.parse(options[:from])
          @parsed_to = Utils::TimeParser.parse(options[:to])
          @parsed_timezone = Utils::TimeParser.parse_timezone(options[:time_zone])
        rescue Utils::TimeParser::ParseError => e
          warn "Error parsing time: #{e.message}"
          exit 1
        end

        def log_discovery_info
          warn '=' * 60
          warn 'Discovering Source Metadata'
          warn '=' * 60
          warn "Time Range: #{@original_from} to #{@original_to}"
          if @original_from != @parsed_from || @original_to != @parsed_to
            warn "  (Parsed: #{@parsed_from} to #{@parsed_to})"
          end
          warn "Time Zone: #{@parsed_timezone}"
          warn "Filter: #{options[:filter] || 'none (all sources)'}"
          warn '-' * 60
          warn 'Running aggregation query to discover sources...'
          $stderr.puts
        end

        def perform_discovery
          client.discover_source_metadata(
            from_time: @parsed_from,
            to_time: @parsed_to,
            time_zone: @parsed_timezone,
            filter: options[:filter]
          )
        end
      end
    end
  end
end
