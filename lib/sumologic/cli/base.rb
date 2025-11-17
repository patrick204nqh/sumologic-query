# frozen_string_literal: true

module Sumologic
  class CLI < Thor
    # Base module with shared CLI functionality
    # Provides client management and debug mode setup
    module Base
      def self.included(base)
        base.class_eval do
          class_option :debug, type: :boolean, aliases: '-d', desc: 'Enable debug output'
          class_option :output, type: :string, aliases: '-o', desc: 'Output file (default: stdout)'

          def self.exit_on_failure?
            true
          end

          # Hook to setup debug mode before each command
          def initialize(*args)
            super
            setup_debug_mode
          end

          no_commands do
            def setup_debug_mode
              $DEBUG = true if options[:debug]
            end

            def client
              @client ||= create_client
            end

            def create_client
              Client.new
            rescue AuthenticationError => e
              error "Authentication Error: #{e.message}"
              error "\nPlease set environment variables:"
              error "  export SUMO_ACCESS_ID='your_access_id'"
              error "  export SUMO_ACCESS_KEY='your_access_key'"
              error "  export SUMO_DEPLOYMENT='us2'  # Optional, defaults to us2"
              exit 1
            rescue Error => e
              error "Error: #{e.message}"
              exit 1
            end

            def error(message)
              warn message
            end
          end
        end
      end
    end
  end
end
