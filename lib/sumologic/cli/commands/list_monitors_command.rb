# frozen_string_literal: true

require_relative 'base_command'

module Sumologic
  class CLI < Thor
    module Commands
      # Handles the list-monitors command execution
      # Uses the monitors search API for flat, filterable results
      class ListMonitorsCommand < BaseCommand
        def execute
          list_resource(label: 'monitors', key: :monitors) do
            client.list_monitors(
              query: options[:query],
              status: options[:status],
              limit: options[:limit] || 100
            )
          end
        end
      end
    end
  end
end
