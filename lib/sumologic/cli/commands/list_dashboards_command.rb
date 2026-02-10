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
            dashboards: dashboards.map { |d| format_dashboard(d) }
          )
        end

        private

        def format_dashboard(dashboard)
          {
            id: dashboard['id'],
            title: dashboard['title'],
            description: dashboard['description'],
            folderId: dashboard['folderId'],
            domain: dashboard['domain'],
            refreshInterval: dashboard['refreshInterval'],
            theme: dashboard['theme'],
            contentId: dashboard['contentId']
          }.compact
        end
      end
    end
  end
end
