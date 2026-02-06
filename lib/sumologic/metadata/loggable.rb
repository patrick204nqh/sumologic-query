# frozen_string_literal: true

module Sumologic
  module Metadata
    # Shared logging functionality for metadata classes
    # Provides consistent debug logging with class-specific prefixes
    module Loggable
      private

      # Log informational message (only shows in debug mode)
      def log_info(message)
        warn "[#{log_prefix}] #{message}" if debug_enabled?
      end

      # Log error message (always shows)
      def log_error(message)
        warn "[#{log_prefix} ERROR] #{message}"
      end

      # Check if debug logging is enabled
      def debug_enabled?
        ENV['SUMO_DEBUG'] || $DEBUG
      end

      # Get the class-specific log prefix
      # Override in including class if needed
      def log_prefix
        self.class.name
      end
    end
  end
end
