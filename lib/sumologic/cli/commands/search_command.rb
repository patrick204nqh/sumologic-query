# frozen_string_literal: true

require_relative 'base_command'

module Sumologic
  class CLI < Thor
    module Commands
      # Handles the search command execution
      class SearchCommand < BaseCommand
        def execute
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

        def perform_search
          client.search(
            query: options[:query],
            from_time: options[:from],
            to_time: options[:to],
            time_zone: options[:time_zone],
            limit: options[:limit]
          )
        end

        def display_results_summary(results)
          warn '=' * 60
          warn "Results: #{results.size} messages"
          warn '=' * 60
          $stderr.puts
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

        def launch_interactive_mode(results)
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
            'from' => options[:from],
            'to' => options[:to],
            'time_zone' => options[:time_zone],
            'message_count' => results.size,
            'messages' => results
          }
        end
      end
    end
  end
end
