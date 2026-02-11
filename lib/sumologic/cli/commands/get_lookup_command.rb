# frozen_string_literal: true

require_relative 'base_command'

module Sumologic
  class CLI < Thor
    module Commands
      # Handles the get-lookup command execution
      class GetLookupCommand < BaseCommand
        def execute
          get_resource(label: 'lookup table', id: options[:lookup_id]) do
            client.get_lookup(lookup_id: options[:lookup_id])
          end
        end
      end
    end
  end
end
