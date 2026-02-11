# frozen_string_literal: true

require_relative 'base_command'

module Sumologic
  class CLI < Thor
    module Commands
      # Handles the get-monitor command execution
      class GetMonitorCommand < BaseCommand
        def execute
          get_resource(label: 'monitor', id: options[:monitor_id]) do
            client.get_monitor(monitor_id: options[:monitor_id])
          end
        end
      end
    end
  end
end
