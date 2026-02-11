# frozen_string_literal: true

RSpec.describe 'CLI Commands' do
  let(:client) { instance_double(Sumologic::Client) }
  let(:options) { { output: nil } }

  # ============================================================
  # Simple list commands
  # ============================================================

  describe Sumologic::CLI::Commands::ListCollectorsCommand do
    it 'outputs collectors as JSON' do
      allow(client).to receive(:list_collectors).and_return([{ 'id' => '1', 'name' => 'c1' }])

      command = described_class.new(options, client)
      expect { command.execute }.to output(/"total": 1/).to_stdout
    end
  end

  describe Sumologic::CLI::Commands::ListAppsCommand do
    it 'outputs apps as JSON' do
      allow(client).to receive(:list_apps).and_return([{ 'appId' => 'a1' }])

      command = described_class.new(options, client)
      expect { command.execute }.to output(/"total": 1/).to_stdout
    end
  end

  describe Sumologic::CLI::Commands::ListDashboardsCommand do
    it 'outputs dashboards as JSON' do
      allow(client).to receive(:list_dashboards).with(limit: 100).and_return([{ 'id' => 'd1' }])

      command = described_class.new(options, client)
      expect { command.execute }.to output(/"total": 1/).to_stdout
    end
  end

  describe Sumologic::CLI::Commands::ListHealthEventsCommand do
    it 'outputs health events as JSON' do
      allow(client).to receive(:list_health_events).with(limit: 100).and_return([{ 'eventId' => 'e1' }])

      command = described_class.new(options, client)
      expect { command.execute }.to output(/"total": 1/).to_stdout
    end
  end

  describe Sumologic::CLI::Commands::ListMonitorsCommand do
    it 'outputs monitors as JSON' do
      allow(client).to receive(:list_monitors)
        .with(query: nil, status: nil, limit: 100)
        .and_return([{ 'id' => 'm1' }])

      command = described_class.new(options, client)
      expect { command.execute }.to output(/"total": 1/).to_stdout
    end

    it 'passes query and status filters' do
      allow(client).to receive(:list_monitors)
        .with(query: 'prod', status: 'Critical', limit: 50)
        .and_return([])

      command = described_class.new(options.merge(query: 'prod', status: 'Critical', limit: 50), client)
      expect { command.execute }.to output(/"total": 0/).to_stdout
    end
  end

  # ============================================================
  # Conditional list commands
  # ============================================================

  describe Sumologic::CLI::Commands::ListFieldsCommand do
    it 'lists custom fields by default' do
      allow(client).to receive(:list_fields).and_return([{ 'fieldName' => 'env' }])

      command = described_class.new(options, client)
      expect { command.execute }.to output(/"total": 1/).to_stdout
    end

    it 'lists builtin fields when --builtin is set' do
      allow(client).to receive(:list_builtin_fields).and_return([{ 'fieldName' => '_sourceHost' }])

      command = described_class.new(options.merge(builtin: true), client)
      expect { command.execute }.to output(/"total": 1/).to_stdout
    end
  end

  describe Sumologic::CLI::Commands::ListSourcesCommand do
    it 'lists sources for a specific collector' do
      allow(client).to receive(:list_sources)
        .with(collector_id: '123')
        .and_return([{ 'id' => 's1' }])

      command = described_class.new(options.merge(collector_id: '123'), client)
      expect { command.execute }.to output(/"total": 1/).to_stdout
    end

    it 'lists all sources when no collector_id given' do
      allow(client).to receive(:list_all_sources).and_return(
        [{ 'collector' => { 'id' => '1' }, 'sources' => [{ 'id' => 's1' }] }]
      )

      command = described_class.new(options, client)
      expect { command.execute }.to output(/"total_collectors": 1/).to_stdout
    end
  end

  describe Sumologic::CLI::Commands::ListFoldersCommand do
    it 'fetches personal folder by default' do
      allow(client).to receive(:personal_folder).and_return({ 'id' => 'f1', 'name' => 'Personal' })

      command = described_class.new(options, client)
      expect { command.execute }.to output(/"Personal"/).to_stdout
    end

    it 'fetches a specific folder by ID' do
      allow(client).to receive(:get_folder)
        .with(folder_id: 'abc')
        .and_return({ 'id' => 'abc', 'name' => 'My Folder' })

      command = described_class.new(options.merge(folder_id: 'abc'), client)
      expect { command.execute }.to output(/"My Folder"/).to_stdout
    end

    it 'fetches folder tree when --tree is set' do
      allow(client).to receive(:folder_tree)
        .with(folder_id: nil, max_depth: 3)
        .and_return({ 'id' => 'f1', 'children' => [] })

      command = described_class.new(options.merge(tree: true), client)
      expect { command.execute }.to output(/"children"/).to_stdout
    end
  end

  # ============================================================
  # Simple get commands
  # ============================================================

  describe Sumologic::CLI::Commands::GetMonitorCommand do
    it 'outputs monitor details as JSON' do
      allow(client).to receive(:get_monitor)
        .with(monitor_id: 'm1')
        .and_return({ 'id' => 'm1', 'name' => 'CPU Alert' })

      command = described_class.new(options.merge(monitor_id: 'm1'), client)
      expect { command.execute }.to output(/"CPU Alert"/).to_stdout
    end
  end

  describe Sumologic::CLI::Commands::GetDashboardCommand do
    it 'outputs dashboard details as JSON' do
      allow(client).to receive(:get_dashboard)
        .with(dashboard_id: 'd1')
        .and_return({ 'id' => 'd1', 'title' => 'Overview' })

      command = described_class.new(options.merge(dashboard_id: 'd1'), client)
      expect { command.execute }.to output(/"Overview"/).to_stdout
    end
  end

  describe Sumologic::CLI::Commands::GetLookupCommand do
    it 'outputs lookup table details as JSON' do
      allow(client).to receive(:get_lookup)
        .with(lookup_id: 'lt1')
        .and_return({ 'id' => 'lt1', 'name' => 'GeoIP' })

      command = described_class.new(options.merge(lookup_id: 'lt1'), client)
      expect { command.execute }.to output(/"GeoIP"/).to_stdout
    end
  end

  describe Sumologic::CLI::Commands::GetContentCommand do
    it 'outputs content details as JSON' do
      allow(client).to receive(:get_content)
        .with(path: '/Library/Users/me/Search')
        .and_return({ 'id' => 'c1', 'name' => 'Search' })

      command = described_class.new(options.merge(path: '/Library/Users/me/Search'), client)
      expect { command.execute }.to output(/"Search"/).to_stdout
    end
  end

  # ============================================================
  # Export command
  # ============================================================

  describe Sumologic::CLI::Commands::ExportContentCommand do
    it 'outputs exported content as JSON' do
      allow(client).to receive(:export_content)
        .with(content_id: 'c1')
        .and_return({ 'type' => 'SavedSearchWithScheduleSyncDefinition', 'name' => 'My Search' })

      command = described_class.new(options.merge(content_id: 'c1'), client)
      expect { command.execute }.to output(/"My Search"/).to_stdout
    end
  end
end
