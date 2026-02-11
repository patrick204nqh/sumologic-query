# frozen_string_literal: true

require_relative 'base_command'

module Sumologic
  class CLI < Thor
    module Commands
      # Handles the get-dashboard command execution
      class GetDashboardCommand < BaseCommand
        def execute
          get_resource(label: 'dashboard', id: options[:dashboard_id]) do
            client.get_dashboard(dashboard_id: options[:dashboard_id])
          end
        end
      end
    end
  end
end
