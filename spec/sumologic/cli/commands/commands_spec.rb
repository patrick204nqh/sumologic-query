# frozen_string_literal: true

RSpec.describe 'CLI Commands' do
  let(:client) { instance_double(Sumologic::Client) }
  let(:options) { { output: nil } }

  def capture_stdout_stderr(command)
    stdout = StringIO.new
    stderr = StringIO.new
    original_stdout = $stdout
    original_stderr = $stderr
    $stdout = stdout
    $stderr = stderr
    command.execute
    { stdout: stdout.string, stderr: stderr.string }
  ensure
    $stdout = original_stdout
    $stderr = original_stderr
  end

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
      allow(client).to receive(:list_all_sources)
        .with(collector: nil, name: nil, category: nil, limit: nil)
        .and_return(
          [{ 'collector' => { 'id' => '1' }, 'sources' => [{ 'id' => 's1' }] }]
        )

      command = described_class.new(options, client)
      expect { command.execute }.to output(/"total_collectors": 1/).to_stdout
    end

    it 'passes filter options when listing all sources' do
      allow(client).to receive(:list_all_sources)
        .with(collector: 'web', name: 'nginx', category: 'prod', limit: 10)
        .and_return([])

      command = described_class.new(
        options.merge(collector: 'web', name: 'nginx', category: 'prod', limit: 10), client
      )
      expect { command.execute }.to output(/"total_collectors": 0/).to_stdout
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
  # Search command
  # ============================================================

  describe Sumologic::CLI::Commands::SearchCommand do
    let(:config) { instance_double(Sumologic::Configuration, web_ui_base_url: 'https://service.us2.sumologic.com') }
    let(:search_options) do
      {
        output: nil,
        query: '_sourceCategory=prod error',
        from: '2024-01-01T00:00:00Z',
        to: '2024-01-02T00:00:00Z',
        time_zone: 'UTC',
        limit: 100,
        aggregate: false,
        interactive: false
      }
    end

    before do
      allow(client).to receive(:config).and_return(config)
    end

    it 'includes search_url in JSON output for message queries' do
      allow(client).to receive(:search).and_return([{ '_raw' => 'log line' }])

      command = described_class.new(search_options, client)
      output = capture_stdout_stderr(command)

      parsed = JSON.parse(output[:stdout])
      expect(parsed).to have_key('search_url')
      expect(parsed['search_url']).to include('service.us2.sumologic.com')
      expect(parsed['search_url']).to include('startTime=')
      expect(parsed['search_url']).to include('endTime=')
      expect(parsed['search_url']).to include('query=')
    end

    it 'includes search_url in JSON output for aggregate queries' do
      agg_options = search_options.merge(query: '_sourceCategory=prod | count by _sourceHost', aggregate: true)
      allow(client).to receive(:search_aggregation).and_return([{ '_count' => '5' }])

      command = described_class.new(agg_options, client)
      output = capture_stdout_stderr(command)

      parsed = JSON.parse(output[:stdout])
      expect(parsed).to have_key('search_url')
      expect(parsed['search_url']).to include('service.us2.sumologic.com')
    end

    it 'prints search URL in stderr summary' do
      allow(client).to receive(:search).and_return([])

      command = described_class.new(search_options, client)
      output = capture_stdout_stderr(command)

      expect(output[:stderr]).to include('Open in Sumo:')
      expect(output[:stderr]).to include('service.us2.sumologic.com')
    end

    it 'encodes query and uses epoch-ms timestamps in URL' do
      allow(client).to receive(:search).and_return([])

      command = described_class.new(search_options, client)
      output = capture_stdout_stderr(command)

      parsed = JSON.parse(output[:stdout])
      url = parsed['search_url']

      # 2024-01-01T00:00:00Z = 1704067200000 ms
      expect(url).to include('startTime=1704067200000')
      # 2024-01-02T00:00:00Z = 1704153600000 ms
      expect(url).to include('endTime=1704153600000')
      # query should be URL-encoded (spaces become %20, pipes become %7C)
      expect(url).not_to include(' ')
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
