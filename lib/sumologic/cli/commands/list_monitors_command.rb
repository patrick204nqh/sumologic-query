# frozen_string_literal: true

require_relative 'base_command'

module Sumologic
  class CLI < Thor
    module Commands
      # Handles the list-monitors command execution
      class ListMonitorsCommand < BaseCommand
        def execute
          warn 'Fetching monitors...'
          monitors = client.list_monitors(limit: options[:limit] || 100)

          output_json(
            total: monitors.size,
            monitors: monitors.map { |m| format_monitor(m) }
          )
        end

        private

        def format_monitor(monitor)
          {
            id: monitor['id'],
            name: monitor['name'],
            description: monitor['description'],
            type: monitor['type'],
            monitorType: monitor['monitorType'],
            isDisabled: monitor['isDisabled'],
            status: monitor['status'],
            createdAt: monitor['createdAt'],
            modifiedAt: monitor['modifiedAt']
          }.compact
        end
      end
    end
  end
end
