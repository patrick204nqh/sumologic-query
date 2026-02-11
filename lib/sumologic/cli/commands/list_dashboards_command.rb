# frozen_string_literal: true

require_relative 'base_command'

module Sumologic
  class CLI < Thor
    module Commands
      # Handles the list-dashboards command execution
      class ListDashboardsCommand < BaseCommand
        def execute
          warn 'Fetching dashboards...'
          dashboards = client.list_dashboards(limit: options[:limit] || 100)

          output_json(
            total: dashboards.size,
            dashboards: dashboards
          )
        end
      end
    end
  end
end
