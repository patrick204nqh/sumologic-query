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
            apps: apps
          )
        end
      end
    end
  end
end
