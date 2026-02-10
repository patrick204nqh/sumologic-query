# frozen_string_literal: true

require_relative 'base_command'

module Sumologic
  class CLI < Thor
    module Commands
      # Handles the get-content command execution
      class GetContentCommand < BaseCommand
        def execute
          path = options[:path]
          warn "Looking up content at path: #{path}..."
          content = client.get_content(path: path)

          output_json(content)
        end
      end
    end
  end
end
