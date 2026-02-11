# frozen_string_literal: true

require 'fileutils'

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
            # Create parent directories if they don't exist
            output_dir = File.dirname(options[:output])
            FileUtils.mkdir_p(output_dir) unless output_dir == '.'

            File.write(options[:output], json_output)
            warn "\nResults saved to: #{options[:output]}"
          else
            puts json_output
          end
        end
      end
    end
  end
end
