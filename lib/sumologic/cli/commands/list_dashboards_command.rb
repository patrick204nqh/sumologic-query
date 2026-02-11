# frozen_string_literal: true

require_relative 'base_command'

module Sumologic
  class CLI < Thor
    module Commands
      # Handles the list-dashboards command execution
      class ListDashboardsCommand < BaseCommand
        def execute
          list_resource(label: 'dashboards', key: :dashboards) do
            client.list_dashboards(limit: options[:limit] || 100)
          end
        end
      end
    end
  end
end
