# frozen_string_literal: true

module Sumologic
  class CLI < Thor
    module Commands
      # Search command implementation
      # Handles log searching and interactive mode
      module Search
        def self.included(base)
          base.class_eval do
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

                # Interactive mode with FZF
                sumo-query search --query 'error' \\
                  --from '2025-11-13T14:00:00' --to '2025-11-13T15:00:00' \\
                  --interactive
            DESC
            option :query, type: :string, required: true, aliases: '-q', desc: 'Search query'
            option :from, type: :string, required: true, aliases: '-f', desc: 'Start time (ISO 8601)'
            option :to, type: :string, required: true, aliases: '-t', desc: 'End time (ISO 8601)'
            option :time_zone, type: :string, default: 'UTC', aliases: '-z', desc: 'Time zone'
            option :limit, type: :numeric, aliases: '-l', desc: 'Maximum messages to return'
            option :interactive, type: :boolean, aliases: '-i', desc: 'Launch interactive browser (requires fzf)'
            def search
              log_search_info
              results = execute_search(client)

              warn '=' * 60
              warn "Results: #{results.size} messages"
              warn '=' * 60
              $stderr.puts

              if options[:interactive]
                launch_interactive_mode(results)
              else
                output_search_results(results)
              end
            end
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

        def launch_interactive_mode(results)
          require_relative '../../interactive'

          # Format results for interactive mode
          formatted_results = {
            'query' => options[:query],
            'from' => options[:from],
            'to' => options[:to],
            'time_zone' => options[:time_zone],
            'message_count' => results.size,
            'messages' => results
          }

          Sumologic::Interactive.launch(formatted_results)
        rescue Sumologic::Interactive::Error => e
          error e.message
          exit 1
        end
      end
    end
  end
end
