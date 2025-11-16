# frozen_string_literal: true

module Sumologic
  module Interactive
    class FzfViewer
      module HeaderBuilder
        extend self

        def build_header_text(results, messages)
          [
            build_column_headers,
            build_info_line(results, messages),
            build_search_tips,
            build_keybindings_help
          ].join("\n")
        end

        def build_column_headers
          "#{Formatter.pad('TIME', Config::TIME_WIDTH)} " \
            "#{Formatter.pad('LEVEL', Config::LEVEL_WIDTH)} " \
            "#{Formatter.pad('SOURCE', Config::SOURCE_WIDTH)} MESSAGE"
        end

        def build_info_line(results, messages)
          query = results['query'] || 'N/A'
          count = messages.size
          sources = messages.map { |m| m['map']['_source'] }.compact.uniq.size

          "#{count} msgs | #{sources} sources | Query: #{Formatter.truncate(query, 40)}"
        end

        def build_search_tips
          "💡 Simple text search (case-insensitive) - searches all JSON fields and log content"
        end

        def build_keybindings_help
          'Enter=select Tab=view Ctrl-T=toggle-search Ctrl-S=save Ctrl-Y=copy Ctrl-E=export Ctrl-Q=quit'
        end
      end
    end
  end
end
