# frozen_string_literal: true

require_relative 'base_command'

module Sumologic
  class CLI < Thor
    module Commands
      # Handles the list-apps command execution
      class ListAppsCommand < BaseCommand
        def execute
          list_resource(label: 'app catalog', key: :apps) { client.list_apps }
        end
      end
    end
  end
end
