# frozen_string_literal: true

require_relative 'base_command'

module Sumologic
  class CLI < Thor
    module Commands
      # Handles the list-apps command execution
      class ListAppsCommand < BaseCommand
        def execute
          warn 'Fetching app catalog...'
          apps = client.list_apps

          output_json(
            total: apps.size,
            apps: apps.map { |a| format_app(a) }
          )
        end

        private

        def format_app(app)
          {
            appId: app['appId'] || app['uuid'],
            name: app['appDefinition']&.dig('name') || app['name'],
            description: app['appDefinition']&.dig('description') || app['description']
          }.compact
        end
      end
    end
  end
end
