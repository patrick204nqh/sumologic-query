# frozen_string_literal: true

module Sumologic
  module Interactive
    class FzfViewer
      module Config
        # Display configuration
        TIME_WIDTH = 8
        LEVEL_WIDTH = 7
        SOURCE_WIDTH = 25
        MESSAGE_PREVIEW_LENGTH = 80
        SEARCHABLE_PADDING = 5

        # Searchable field names
        SEARCHABLE_FIELDS = %w[
          _source
          _sourcecategory
          _sourcename
          _collector
          _sourcehost
          region
          _group
          _tier
          _view
        ].freeze

        # ANSI color codes
        COLORS = {
          red: "\e[31m",
          yellow: "\e[33m",
          cyan: "\e[36m",
          gray: "\e[90m",
          reset: "\e[0m"
        }.freeze
      end
    end
  end
end
