# frozen_string_literal: true

require_relative 'base_command'
require_relative '../../utils/time_parser'

module Sumologic
  class CLI < Thor
    module Commands
      # Handles the search command execution
      class SearchCommand < BaseCommand
        def execute
          parse_time_options
          log_search_info
          results = perform_search

          display_results_summary(results)

          if options[:interactive]
            launch_interactive_mode(results)
          else
            output_search_results(results)
          end
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

        def log_search_info
          warn '=' * 60
          warn 'Sumo Logic Search Query'
          warn '=' * 60
          warn "Time Range: #{@original_from} to #{@original_to}"
          if @original_from != @parsed_from || @original_to != @parsed_to
            warn "  (Parsed: #{@parsed_from} to #{@parsed_to})"
          end
          warn "Query: #{options[:query]}"
          warn "Limit: #{options[:limit] || 'unlimited'}"
          warn '-' * 60
          warn 'Creating search job...'
          $stderr.puts
        end

        def perform_search
          if options[:aggregate]
            client.search_aggregation(
              query: options[:query],
              from_time: @parsed_from,
              to_time: @parsed_to,
              time_zone: @parsed_timezone,
              limit: options[:limit]
            )
          else
            client.search(
              query: options[:query],
              from_time: @parsed_from,
              to_time: @parsed_to,
              time_zone: @parsed_timezone,
              limit: options[:limit]
            )
          end
        end

        def display_results_summary(results)
          result_type = options[:aggregate] ? 'records' : 'messages'
          warn '=' * 60
          warn "Results: #{results.size} #{result_type}"
          warn '=' * 60
          $stderr.puts
        end

        def output_search_results(results)
          if options[:aggregate]
            output_json(
              query: options[:query],
              from: @parsed_from,
              to: @parsed_to,
              from_original: @original_from,
              to_original: @original_to,
              time_zone: @parsed_timezone,
              record_count: results.size,
              records: results
            )
          else
            output_json(
              query: options[:query],
              from: @parsed_from,
              to: @parsed_to,
              from_original: @original_from,
              to_original: @original_to,
              time_zone: @parsed_timezone,
              message_count: results.size,
              messages: results
            )
          end
        end

        def launch_interactive_mode(results)
          if options[:aggregate]
            warn 'Interactive mode is not supported for aggregation queries'
            output_search_results(results)
            return
          end

          require_relative '../../interactive'

          formatted_results = build_formatted_results(results)
          Sumologic::Interactive.launch(formatted_results)
        rescue Sumologic::Interactive::Error => e
          warn e.message
          exit 1
        end

        def build_formatted_results(results)
          {
            'query' => options[:query],
            'from' => @parsed_from,
            'to' => @parsed_to,
            'time_zone' => @parsed_timezone,
            'message_count' => results.size,
            'messages' => results
          }
        end
      end
    end
  end
end
