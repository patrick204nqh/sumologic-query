# frozen_string_literal: true

module Sumologic
  module Metadata
    # Value object representing source metadata discovered from logs
    class SourceMetadata
      attr_reader :name, :category, :message_count

      def initialize(name:, category:, message_count:)
        @name = name
        @category = category
        @message_count = message_count
      end

      # Convert to hash for JSON serialization
      def to_h
        {
          'name' => @name,
          'category' => @category,
          'message_count' => @message_count
        }.compact
      end

      # Sort by message count (descending)
      def <=>(other)
        other.message_count <=> @message_count
      end
    end
  end
end
