# frozen_string_literal: true

require_relative 'base_command'

module Sumologic
  class CLI < Thor
    module Commands
      # Handles the list-fields command execution
      class ListFieldsCommand < BaseCommand
        def execute
          if options[:builtin]
            warn 'Fetching built-in fields...'
            fields = client.list_builtin_fields
          else
            warn 'Fetching custom fields...'
            fields = client.list_fields
          end

          output_json(
            total: fields.size,
            fields: fields
          )
        end
      end
    end
  end
end
