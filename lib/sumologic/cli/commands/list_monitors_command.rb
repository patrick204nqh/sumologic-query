# frozen_string_literal: true

require_relative 'base_command'

module Sumologic
  class CLI < Thor
    module Commands
      # Handles the list-monitors command execution
      # Uses the monitors search API for flat, filterable results
      class ListMonitorsCommand < BaseCommand
        def execute
          warn 'Fetching monitors...'
          monitors = client.list_monitors(
            query: options[:query],
            status: options[:status],
            limit: options[:limit] || 100
          )

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
            monitorType: monitor['monitorType'],
            status: monitor['status'],
            isDisabled: monitor['isDisabled'],
            path: monitor['path'],
            contentType: monitor['contentType'],
            createdAt: monitor['createdAt'],
            modifiedAt: monitor['modifiedAt']
          }.compact
        end
      end
    end
  end
end
