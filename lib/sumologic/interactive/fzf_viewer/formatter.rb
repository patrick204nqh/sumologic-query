# frozen_string_literal: true

module Sumologic
  module Interactive
    class FzfViewer
      module Formatter
        extend self

        def format_time(timestamp_ms)
          return 'N/A' unless timestamp_ms
          Time.at(timestamp_ms.to_i / 1000).strftime('%H:%M:%S')
        end

        def format_level(level)
          level_str = level.to_s.upcase.ljust(Config::LEVEL_WIDTH)
          colorize_level(level_str)
        end

        def colorize_level(level_str)
          case level_str.strip
          when 'ERROR', 'FATAL', 'CRITICAL'
            "#{Config::COLORS[:red]}#{level_str}#{Config::COLORS[:reset]}"
          when 'WARN', 'WARNING'
            "#{Config::COLORS[:yellow]}#{level_str}#{Config::COLORS[:reset]}"
          when 'INFO'
            "#{Config::COLORS[:cyan]}#{level_str}#{Config::COLORS[:reset]}"
          when 'DEBUG', 'TRACE'
            "#{Config::COLORS[:gray]}#{level_str}#{Config::COLORS[:reset]}"
          else
            level_str
          end
        end

        def sanitize(text)
          text.to_s.gsub(/[\n\r\t]/, ' ').squeeze(' ')
        end

        def truncate(text, length)
          text = text.to_s
          text.length > length ? "#{text[0...(length - 3)]}..." : text
        end

        def pad(text, width)
          text.ljust(width)
        end
      end
    end
  end
end
