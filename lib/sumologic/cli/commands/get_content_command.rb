# frozen_string_literal: true

require_relative 'base_command'

module Sumologic
  class CLI < Thor
    module Commands
      # Handles the get-content command execution
      class GetContentCommand < BaseCommand
        def execute
          get_resource(label: 'content at path:', id: options[:path]) do
            client.get_content(path: options[:path])
          end
        end
      end
    end
  end
end
