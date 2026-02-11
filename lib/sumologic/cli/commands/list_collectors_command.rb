# frozen_string_literal: true

require_relative 'base_command'

module Sumologic
  class CLI < Thor
    module Commands
      # Handles the list-collectors command execution
      class ListCollectorsCommand < BaseCommand
        def execute
          list_resource(label: 'collectors', key: :collectors) do
            client.list_collectors(
              query: options[:query],
              limit: options[:limit]
            )
          end
        end
      end
    end
  end
end
