# frozen_string_literal: true

require_relative 'base_command'

module Sumologic
  class CLI < Thor
    module Commands
      # Handles the list-health-events command execution
      class ListHealthEventsCommand < BaseCommand
        def execute
          list_resource(label: 'health events', key: :healthEvents) do
            client.list_health_events(limit: options[:limit] || 100)
          end
        end
      end
    end
  end
end
