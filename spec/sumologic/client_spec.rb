# frozen_string_literal: true

RSpec.describe Sumologic::Client do
  describe '#initialize' do
    context 'with environment variables set' do
      before do
        ENV['SUMO_ACCESS_ID'] = 'test_id'
        ENV['SUMO_ACCESS_KEY'] = 'test_key'
        ENV['SUMO_DEPLOYMENT'] = 'us2'
      end

      after do
        ENV.delete('SUMO_ACCESS_ID')
        ENV.delete('SUMO_ACCESS_KEY')
        ENV.delete('SUMO_DEPLOYMENT')
      end

      it 'creates a client with environment credentials' do
        client = described_class.new

        expect(client.config.access_id).to eq('test_id')
        expect(client.config.access_key).to eq('test_key')
        expect(client.config.deployment).to eq('us2')
      end

      it 'uses us2 as default deployment' do
        ENV.delete('SUMO_DEPLOYMENT')
        client = described_class.new

        expect(client.config.deployment).to eq('us2')
      end
    end

    context 'with explicit configuration' do
      it 'creates a client with provided configuration' do
        config = Sumologic::Configuration.new
        config.access_id = 'explicit_id'
        config.access_key = 'explicit_key'
        config.deployment = 'eu'

        client = described_class.new(config)

        expect(client.config.access_id).to eq('explicit_id')
        expect(client.config.access_key).to eq('explicit_key')
        expect(client.config.deployment).to eq('eu')
      end
    end

    context 'without credentials' do
      before do
        ENV.delete('SUMO_ACCESS_ID')
        ENV.delete('SUMO_ACCESS_KEY')
      end

      it 'raises AuthenticationError for missing access_id' do
        config = Sumologic::Configuration.new
        config.access_key = 'key'

        expect do
          described_class.new(config)
        end.to raise_error(Sumologic::AuthenticationError, 'SUMO_ACCESS_ID not set')
      end

      it 'raises AuthenticationError for missing access_key' do
        config = Sumologic::Configuration.new
        config.access_id = 'id'

        expect do
          described_class.new(config)
        end.to raise_error(Sumologic::AuthenticationError, 'SUMO_ACCESS_KEY not set')
      end
    end
  end

  describe 'public API' do
    let(:client) do
      ENV['SUMO_ACCESS_ID'] = 'test_id'
      ENV['SUMO_ACCESS_KEY'] = 'test_key'
      described_class.new
    end

    after do
      ENV.delete('SUMO_ACCESS_ID')
      ENV.delete('SUMO_ACCESS_KEY')
    end

    it 'responds to search' do
      expect(client).to respond_to(:search)
    end

    it 'responds to search_aggregation' do
      expect(client).to respond_to(:search_aggregation)
    end

    it 'responds to list_collectors' do
      expect(client).to respond_to(:list_collectors)
    end

    it 'responds to list_sources' do
      expect(client).to respond_to(:list_sources)
    end

    it 'responds to list_all_sources' do
      expect(client).to respond_to(:list_all_sources)
    end

    it 'responds to discover_dynamic_sources' do
      expect(client).to respond_to(:discover_dynamic_sources)
    end

    # Monitors API
    it 'responds to list_monitors' do
      expect(client).to respond_to(:list_monitors)
    end

    it 'responds to get_monitor' do
      expect(client).to respond_to(:get_monitor)
    end

    # Folders API
    it 'responds to personal_folder' do
      expect(client).to respond_to(:personal_folder)
    end

    it 'responds to global_folder' do
      expect(client).to respond_to(:global_folder)
    end

    it 'responds to get_folder' do
      expect(client).to respond_to(:get_folder)
    end

    it 'responds to folder_tree' do
      expect(client).to respond_to(:folder_tree)
    end

    # Dashboards API
    it 'responds to list_dashboards' do
      expect(client).to respond_to(:list_dashboards)
    end

    it 'responds to get_dashboard' do
      expect(client).to respond_to(:get_dashboard)
    end

    it 'responds to search_dashboards' do
      expect(client).to respond_to(:search_dashboards)
    end

    # Health Events API
    it 'responds to list_health_events' do
      expect(client).to respond_to(:list_health_events)
    end

    # Fields API
    it 'responds to list_fields' do
      expect(client).to respond_to(:list_fields)
    end

    it 'responds to list_builtin_fields' do
      expect(client).to respond_to(:list_builtin_fields)
    end

    # Lookup Tables API
    it 'responds to get_lookup' do
      expect(client).to respond_to(:get_lookup)
    end

    # Apps API
    it 'responds to list_apps' do
      expect(client).to respond_to(:list_apps)
    end
  end
end
