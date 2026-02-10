# frozen_string_literal: true

require_relative 'base_command'

module Sumologic
  class CLI < Thor
    module Commands
      # Handles the export-content command execution
      class ExportContentCommand < BaseCommand
        def execute
          content_id = options[:content_id]
          warn "Exporting content #{content_id}..."
          result = client.export_content(content_id: content_id)

          output_json(result)
        end
      end
    end
  end
end
