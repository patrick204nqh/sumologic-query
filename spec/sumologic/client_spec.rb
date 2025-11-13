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

        expect(client.access_id).to eq('test_id')
        expect(client.access_key).to eq('test_key')
        expect(client.deployment).to eq('us2')
      end

      it 'uses us2 as default deployment' do
        ENV.delete('SUMO_DEPLOYMENT')
        client = described_class.new

        expect(client.deployment).to eq('us2')
      end
    end

    context 'with explicit parameters' do
      it 'creates a client with provided credentials' do
        client = described_class.new(
          access_id: 'explicit_id',
          access_key: 'explicit_key',
          deployment: 'eu'
        )

        expect(client.access_id).to eq('explicit_id')
        expect(client.access_key).to eq('explicit_key')
        expect(client.deployment).to eq('eu')
      end
    end

    context 'without credentials' do
      before do
        ENV.delete('SUMO_ACCESS_ID')
        ENV.delete('SUMO_ACCESS_KEY')
      end

      it 'raises AuthenticationError for missing access_id' do
        expect do
          described_class.new(access_key: 'key')
        end.to raise_error(Sumologic::AuthenticationError, 'SUMO_ACCESS_ID not set')
      end

      it 'raises AuthenticationError for missing access_key' do
        expect do
          described_class.new(access_id: 'id')
        end.to raise_error(Sumologic::AuthenticationError, 'SUMO_ACCESS_KEY not set')
      end
    end
  end

  describe '#deployment_url' do
    let(:client) do
      described_class.new(
        access_id: 'test_id',
        access_key: 'test_key',
        deployment: 'us2'
      )
    end

    it 'returns correct URL for us1' do
      url = client.send(:deployment_url, 'us1')
      expect(url).to eq('https://api.sumologic.com/api/v1')
    end

    it 'returns correct URL for us2' do
      url = client.send(:deployment_url, 'us2')
      expect(url).to eq('https://api.us2.sumologic.com/api/v1')
    end

    it 'returns correct URL for eu' do
      url = client.send(:deployment_url, 'eu')
      expect(url).to eq('https://api.eu.sumologic.com/api/v1')
    end

    it 'returns correct URL for au' do
      url = client.send(:deployment_url, 'au')
      expect(url).to eq('https://api.au.sumologic.com/api/v1')
    end

    it 'handles custom deployment codes' do
      url = client.send(:deployment_url, 'custom')
      expect(url).to eq('https://api.custom.sumologic.com/api/v1')
    end

    it 'allows full URL override' do
      url = client.send(:deployment_url, 'https://custom.example.com/api/v1')
      expect(url).to eq('https://custom.example.com/api/v1')
    end
  end

  describe '#auth_header' do
    let(:client) do
      described_class.new(
        access_id: 'test_id',
        access_key: 'test_key',
        deployment: 'us2'
      )
    end

    it 'generates correct Basic Auth header' do
      header = client.send(:auth_header)
      expected = "Basic #{Base64.strict_encode64('test_id:test_key')}"

      expect(header).to eq(expected)
    end
  end

  describe 'error handling' do
    let(:client) do
      described_class.new(
        access_id: 'test_id',
        access_key: 'test_key',
        deployment: 'us2'
      )
    end

    it 'defines TimeoutError' do
      expect do
        raise Sumologic::TimeoutError, 'Timeout'
      end.to raise_error(Sumologic::TimeoutError)
    end

    it 'defines AuthenticationError' do
      expect do
        raise Sumologic::AuthenticationError, 'Auth failed'
      end.to raise_error(Sumologic::AuthenticationError)
    end

    it 'defines general Error' do
      expect do
        raise Sumologic::Error, 'Something went wrong'
      end.to raise_error(Sumologic::Error)
    end
  end
end
