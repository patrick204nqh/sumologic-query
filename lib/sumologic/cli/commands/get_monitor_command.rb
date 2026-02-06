# frozen_string_literal: true

require_relative 'base_command'

module Sumologic
  class CLI < Thor
    module Commands
      # Handles the get-monitor command execution
      class GetMonitorCommand < BaseCommand
        def execute
          monitor_id = options[:monitor_id]
          warn "Fetching monitor #{monitor_id}..."
          monitor = client.get_monitor(monitor_id: monitor_id)

          output_json(monitor)
        end
      end
    end
  end
end
