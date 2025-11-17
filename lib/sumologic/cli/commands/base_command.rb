# frozen_string_literal: true

module Sumologic
  class CLI < Thor
    module Commands
      # Base class for all CLI commands
      # Provides common functionality like client creation, output handling, and formatting
      class BaseCommand
        attr_reader :options, :client

        def initialize(options, client)
          @options = options
          @client = client
        end

        private

        def output_json(data)
          json_output = JSON.pretty_generate(data)

          if options[:output]
            File.write(options[:output], json_output)
            warn "\nResults saved to: #{options[:output]}"
          else
            puts json_output
          end
        end

        def format_collector(collector)
          {
            id: collector['id'],
            name: collector['name'],
            collectorType: collector['collectorType'],
            alive: collector['alive'],
            category: collector['category']
          }
        end

        def format_source(source)
          {
            id: source['id'],
            name: source['name'],
            category: source['category'],
            sourceType: source['sourceType'],
            alive: source['alive']
          }
        end
      end
    end
  end
end
