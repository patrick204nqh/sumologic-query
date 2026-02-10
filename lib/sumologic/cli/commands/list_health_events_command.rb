# frozen_string_literal: true

require_relative 'base_command'

module Sumologic
  class CLI < Thor
    module Commands
      # Handles the list-health-events command execution
      class ListHealthEventsCommand < BaseCommand
        def execute
          warn 'Fetching health events...'
          events = client.list_health_events(limit: options[:limit] || 100)

          output_json(
            total: events.size,
            healthEvents: events
          )
        end
      end
    end
  end
end
