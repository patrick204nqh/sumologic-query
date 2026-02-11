# frozen_string_literal: true

require_relative 'base_command'

module Sumologic
  class CLI < Thor
    module Commands
      # Handles the list-collectors command execution
      class ListCollectorsCommand < BaseCommand
        def execute
          list_resource(label: 'collectors', key: :collectors) { client.list_collectors }
        end
      end
    end
  end
end
