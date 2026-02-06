# frozen_string_literal: true

require_relative 'base_command'

module Sumologic
  class CLI < Thor
    module Commands
      # Handles the list-folders command execution
      class ListFoldersCommand < BaseCommand
        def execute
          if options[:tree]
            fetch_tree
          elsif options[:folder_id]
            fetch_folder
          else
            fetch_personal
          end
        end

        private

        def fetch_personal
          warn 'Fetching personal folder...'
          folder = client.personal_folder
          output_folder_with_children(folder)
        end

        def fetch_folder
          folder_id = options[:folder_id]
          warn "Fetching folder #{folder_id}..."
          folder = client.get_folder(folder_id: folder_id)
          output_folder_with_children(folder)
        end

        def fetch_tree
          folder_id = options[:folder_id]
          max_depth = options[:depth] || 3

          if folder_id
            warn "Fetching folder tree for #{folder_id} (depth: #{max_depth})..."
          else
            warn "Fetching personal folder tree (depth: #{max_depth})..."
          end

          tree = client.folder_tree(folder_id: folder_id, max_depth: max_depth)
          output_json(tree)
        end

        def output_folder_with_children(folder)
          children = folder['children'] || []
          output_json(
            id: folder['id'],
            name: folder['name'],
            description: folder['description'],
            itemType: folder['itemType'],
            childCount: children.size,
            children: children.map { |c| format_child(c) }
          )
        end

        def format_child(child)
          {
            id: child['id'],
            name: child['name'],
            itemType: child['itemType'],
            description: child['description']
          }.compact
        end
      end
    end
  end
end
