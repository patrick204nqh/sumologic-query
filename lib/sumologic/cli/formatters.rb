# frozen_string_literal: true

module Sumologic
  class CLI < Thor
    # Formatters for CLI output
    # Provides methods to format API responses for display
    module Formatters
      # Format collector data for output
      def format_collector(collector)
        {
          id: collector['id'],
          name: collector['name'],
          collectorType: collector['collectorType'],
          alive: collector['alive'],
          category: collector['category']
        }
      end

      # Format source data for output
      def format_source(source)
        {
          id: source['id'],
          name: source['name'],
          category: source['category'],
          sourceType: source['sourceType'],
          alive: source['alive']
        }
      end
    end
  end
end
