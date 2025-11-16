# frozen_string_literal: true

module Sumologic
  module Interactive
    class FzfViewer
      module SearchableBuilder
        module_function

        def build_searchable_content(map)
          parts = []

          add_primary_content(parts, map)
          add_standard_fields(parts, map)
          add_custom_fields(parts, map)

          parts.compact.join(' ')
        end

        def add_primary_content(parts, map)
          parts << Formatter.sanitize(map['_raw'] || map['message'] || '')
        end

        def add_standard_fields(parts, map)
          Config::SEARCHABLE_FIELDS.each do |field|
            parts << map[field] if map[field]
          end
        end

        def add_custom_fields(parts, map)
          map.each do |key, value|
            next if key.start_with?('_')
            next if value.nil? || value.to_s.empty?

            parts << "#{key}:#{value}"
          end
        end
      end
    end
  end
end
