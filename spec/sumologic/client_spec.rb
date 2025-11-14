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

    it 'responds to list_collectors' do
      expect(client).to respond_to(:list_collectors)
    end

    it 'responds to list_sources' do
      expect(client).to respond_to(:list_sources)
    end

    it 'responds to list_all_sources' do
      expect(client).to respond_to(:list_all_sources)
    end
  end
end
