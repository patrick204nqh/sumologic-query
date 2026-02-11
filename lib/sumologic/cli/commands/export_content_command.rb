# frozen_string_literal: true

require_relative 'base_command'

module Sumologic
  class CLI < Thor
    module Commands
      # Handles the export-content command execution
      class ExportContentCommand < BaseCommand
        def execute
          get_resource(label: 'content', id: options[:content_id]) do
            client.export_content(content_id: options[:content_id])
          end
        end
      end
    end
  end
end
