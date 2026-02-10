# frozen_string_literal: true

require_relative 'base_command'

module Sumologic
  class CLI < Thor
    module Commands
      # Handles the get-lookup command execution
      class GetLookupCommand < BaseCommand
        def execute
          lookup_id = options[:lookup_id]
          warn "Fetching lookup table #{lookup_id}..."
          lookup = client.get_lookup(lookup_id: lookup_id)

          output_json(lookup)
        end
      end
    end
  end
end
