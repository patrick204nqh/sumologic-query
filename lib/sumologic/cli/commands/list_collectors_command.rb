# frozen_string_literal: true

require_relative 'base_command'

module Sumologic
  class CLI < Thor
    module Commands
      # Handles the list-collectors command execution
      class ListCollectorsCommand < BaseCommand
        def execute
          warn 'Fetching collectors...'
          collectors = client.list_collectors

          output_json(
            total: collectors.size,
            collectors: collectors.map { |c| format_collector(c) }
          )
        end
      end
    end
  end
end
