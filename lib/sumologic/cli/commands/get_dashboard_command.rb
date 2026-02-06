# frozen_string_literal: true

require_relative 'base_command'

module Sumologic
  class CLI < Thor
    module Commands
      # Handles the get-dashboard command execution
      class GetDashboardCommand < BaseCommand
        def execute
          dashboard_id = options[:dashboard_id]
          warn "Fetching dashboard #{dashboard_id}..."
          dashboard = client.get_dashboard(dashboard_id: dashboard_id)

          output_json(dashboard)
        end
      end
    end
  end
end
