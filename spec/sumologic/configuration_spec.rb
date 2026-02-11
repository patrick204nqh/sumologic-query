# frozen_string_literal: true

RSpec.describe Sumologic::Configuration do
  describe '#initialize' do
    context 'with environment variables set' do
      before do
        ENV['SUMO_ACCESS_ID'] = 'env_id'
        ENV['SUMO_ACCESS_KEY'] = 'env_key'
        ENV['SUMO_DEPLOYMENT'] = 'eu'
      end

      after do
        ENV.delete('SUMO_ACCESS_ID')
        ENV.delete('SUMO_ACCESS_KEY')
        ENV.delete('SUMO_DEPLOYMENT')
      end

      it 'loads credentials from environment' do
        config = described_class.new

        expect(config.access_id).to eq('env_id')
        expect(config.access_key).to eq('env_key')
        expect(config.deployment).to eq('eu')
      end
    end

    it 'sets default configuration values' do
      config = described_class.new

      expect(config.initial_poll_interval).to eq(2)
      expect(config.max_poll_interval).to eq(15)
      expect(config.poll_backoff_factor).to eq(1.5)
      expect(config.timeout).to eq(300)
      expect(config.max_messages_per_request).to eq(10_000)
    end

    it 'sets default timeout values' do
      config = described_class.new

      expect(config.connect_timeout).to eq(10)
      expect(config.read_timeout).to eq(60)
    end

    it 'sets default retry values' do
      config = described_class.new

      expect(config.max_retries).to eq(3)
      expect(config.retry_base_delay).to eq(1.0)
      expect(config.retry_max_delay).to eq(30.0)
    end

    it 'defaults to us2 deployment' do
      config = described_class.new

      expect(config.deployment).to eq('us2')
    end
  end

  describe '#base_url' do
    it 'returns correct URL for us1' do
      config = described_class.new
      config.deployment = 'us1'

      expect(config.base_url).to eq('https://api.sumologic.com/api/v1')
    end

    it 'returns correct URL for us2' do
      config = described_class.new
      config.deployment = 'us2'

      expect(config.base_url).to eq('https://api.us2.sumologic.com/api/v1')
    end

    it 'returns correct URL for eu' do
      config = described_class.new
      config.deployment = 'eu'

      expect(config.base_url).to eq('https://api.eu.sumologic.com/api/v1')
    end

    it 'returns correct URL for au' do
      config = described_class.new
      config.deployment = 'au'

      expect(config.base_url).to eq('https://api.au.sumologic.com/api/v1')
    end

    it 'handles custom deployment codes' do
      config = described_class.new
      config.deployment = 'custom'

      expect(config.base_url).to eq('https://api.custom.sumologic.com/api/v1')
    end

    it 'allows full URL override' do
      config = described_class.new
      config.deployment = 'https://custom.api.example.com/api/v1'

      expect(config.base_url).to eq('https://custom.api.example.com/api/v1')
    end
  end

  describe '#web_ui_base_url' do
    it 'returns correct URL for us1' do
      config = described_class.new
      config.deployment = 'us1'

      expect(config.web_ui_base_url).to eq('https://service.sumologic.com')
    end

    it 'returns correct URL for us2' do
      config = described_class.new
      config.deployment = 'us2'

      expect(config.web_ui_base_url).to eq('https://service.us2.sumologic.com')
    end

    it 'returns correct URL for eu' do
      config = described_class.new
      config.deployment = 'eu'

      expect(config.web_ui_base_url).to eq('https://service.eu.sumologic.com')
    end

    it 'returns correct URL for au' do
      config = described_class.new
      config.deployment = 'au'

      expect(config.web_ui_base_url).to eq('https://service.au.sumologic.com')
    end

    it 'handles custom deployment codes' do
      config = described_class.new
      config.deployment = 'custom'

      expect(config.web_ui_base_url).to eq('https://service.custom.sumologic.com')
    end

    it 'converts full API URL to service URL' do
      config = described_class.new
      config.deployment = 'https://api.us2.sumologic.com/api/v1'

      expect(config.web_ui_base_url).to eq('https://service.us2.sumologic.com')
    end
  end

  describe '#validate!' do
    it 'raises AuthenticationError for missing access_id' do
      config = described_class.new
      config.access_key = 'key'

      expect do
        config.validate!
      end.to raise_error(Sumologic::AuthenticationError, 'SUMO_ACCESS_ID not set')
    end

    it 'raises AuthenticationError for missing access_key' do
      config = described_class.new
      config.access_id = 'id'

      expect do
        config.validate!
      end.to raise_error(Sumologic::AuthenticationError, 'SUMO_ACCESS_KEY not set')
    end

    it 'does not raise error when credentials are present' do
      config = described_class.new
      config.access_id = 'id'
      config.access_key = 'key'

      expect { config.validate! }.not_to raise_error
    end
  end
end
