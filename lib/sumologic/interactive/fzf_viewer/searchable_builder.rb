# frozen_string_literal: true

module Sumologic
  module Interactive
    class FzfViewer
      module SearchableBuilder
        extend self

        def build_searchable_content(map)
          parts = []

          # Primary content
          parts << Formatter.sanitize(map['_raw'] || map['message'] || '')

          # Standard fields
          Config::SEARCHABLE_FIELDS.each do |field|
            parts << map[field] if map[field]
          end

          # Custom fields (non-underscore prefixed)
          map.each do |key, value|
            next if key.start_with?('_')
            next if value.nil? || value.to_s.empty?
            parts << "#{key}:#{value}"
          end

          parts.compact.join(' ')
        end
      end
    end
  end
end
