# frozen_string_literal: true

require 'json'

module Sumologic
  class CLI < Thor
    # Output handling for CLI
    # Manages JSON formatting and file/stdout output
    module OutputHandler
      # Output data as JSON to file or stdout
      def output_json(data)
        json_output = JSON.pretty_generate(data)

        if options[:output]
          File.write(options[:output], json_output)
          warn "\nResults saved to: #{options[:output]}"
        else
          puts json_output
        end
      end
    end
  end
end
