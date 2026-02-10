# frozen_string_literal: true

module Sumologic
  module Metadata
    # Value object representing a Sumo Logic Collector
    class CollectorModel
      attr_reader :id, :name, :collector_type, :alive, :category

      def initialize(data)
        @id = data['id']
        @name = data['name']
        @collector_type = data['collectorType']
        @alive = data['alive']
        @category = data['category']
      end

      # Convert to hash for JSON serialization
      def to_h
        {
          'id' => @id,
          'name' => @name,
          'collectorType' => @collector_type,
          'alive' => @alive,
          'category' => @category
        }.compact
      end

      def active?
        @alive == true
      end
    end

    # Value object representing a static Source from collectors API
    class SourceModel
      attr_reader :id, :name, :category, :source_type, :alive

      def initialize(data)
        @id = data['id']
        @name = data['name']
        @category = data['category']
        @source_type = data['sourceType']
        @alive = data['alive']
      end

      # Convert to hash for JSON serialization
      def to_h
        {
          'id' => @id,
          'name' => @name,
          'category' => @category,
          'sourceType' => @source_type,
          'alive' => @alive
        }.compact
      end

      def active?
        @alive == true
      end
    end

    # Value object representing a Dynamic Source discovered from logs
    class DynamicSourceModel
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

    # Value object for collector with its sources
    class CollectorWithSources
      attr_reader :collector, :sources

      def initialize(collector:, sources:)
        @collector = collector.is_a?(CollectorModel) ? collector : CollectorModel.new(collector)
        @sources = sources.map { |s| s.is_a?(SourceModel) ? s : SourceModel.new(s) }
      end

      # Convert to hash for JSON serialization
      def to_h
        {
          'collector' => @collector.to_h,
          'sources' => @sources.map(&:to_h)
        }
      end

      def source_count
        @sources.size
      end
    end

    # Value object representing a Sumo Logic Monitor
    class MonitorModel
      attr_reader :id, :name, :description, :type, :status, :content_type,
                  :monitor_type, :is_disabled, :is_mutable, :created_at, :modified_at

      def initialize(data)
        @id = data['id']
        @name = data['name']
        @description = data['description']
        @type = data['type']
        @status = data['status']
        @content_type = data['contentType']
        @monitor_type = data['monitorType']
        @is_disabled = data['isDisabled']
        @is_mutable = data['isMutable']
        @created_at = data['createdAt']
        @modified_at = data['modifiedAt']
        @raw_data = data
      end

      # Convert to hash for JSON serialization
      def to_h
        {
          'id' => @id,
          'name' => @name,
          'description' => @description,
          'type' => @type,
          'status' => @status,
          'contentType' => @content_type,
          'monitorType' => @monitor_type,
          'isDisabled' => @is_disabled,
          'isMutable' => @is_mutable,
          'createdAt' => @created_at,
          'modifiedAt' => @modified_at
        }.compact
      end

      # Get full raw data (useful for detailed view)
      def to_full_h
        @raw_data
      end

      def enabled?
        !@is_disabled
      end

      def disabled?
        @is_disabled == true
      end
    end

    # Value object representing a Sumo Logic Folder
    class FolderModel
      attr_reader :id, :name, :description, :item_type, :parent_id,
                  :created_at, :created_by, :modified_at, :modified_by

      def initialize(data)
        @id = data['id']
        @name = data['name']
        @description = data['description']
        @item_type = data['itemType']
        @parent_id = data['parentId']
        @created_at = data['createdAt']
        @created_by = data['createdBy']
        @modified_at = data['modifiedAt']
        @modified_by = data['modifiedBy']
        @children = data['children'] || []
        @raw_data = data
      end

      # Convert to hash for JSON serialization
      def to_h
        {
          'id' => @id,
          'name' => @name,
          'description' => @description,
          'itemType' => @item_type,
          'parentId' => @parent_id,
          'createdAt' => @created_at,
          'createdBy' => @created_by,
          'modifiedAt' => @modified_at,
          'modifiedBy' => @modified_by
        }.compact
      end

      # Get full raw data including children
      def to_full_h
        @raw_data
      end

      def children
        @children.map { |c| FolderModel.new(c) }
      end

      def folder?
        @item_type == 'Folder'
      end
    end

    # Value object representing a Sumo Logic Dashboard (v2 API)
    class DashboardModel
      attr_reader :id, :title, :description, :folder_id, :domain,
                  :refresh_interval, :theme, :content_id

      def initialize(data)
        @id = data['id']
        @title = data['title']
        @description = data['description']
        @folder_id = data['folderId']
        @domain = data['domain']
        @refresh_interval = data['refreshInterval']
        @theme = data['theme']
        @content_id = data['contentId']
        @raw_data = data
      end

      # Convert to hash for JSON serialization
      def to_h
        {
          'id' => @id,
          'title' => @title,
          'description' => @description,
          'folderId' => @folder_id,
          'domain' => @domain,
          'refreshInterval' => @refresh_interval,
          'theme' => @theme,
          'contentId' => @content_id
        }.compact
      end

      # Get full raw data (useful for detailed view)
      def to_full_h
        @raw_data
      end
    end
  end
end
