# frozen_string_literal: true

RSpec.describe Sumologic::Metadata::Collector do
  let(:http_client) { instance_double('Sumologic::Http::Client') }
  let(:collector) { described_class.new(http_client: http_client) }

  let(:collectors_response) do
    {
      'collectors' => [
        { 'id' => '1', 'name' => 'prod-web-01', 'category' => 'production/web' },
        { 'id' => '2', 'name' => 'prod-api-01', 'category' => 'production/api' },
        { 'id' => '3', 'name' => 'staging-web-01', 'category' => 'staging/web' },
        { 'id' => '4', 'name' => 'dev-local', 'category' => '' }
      ]
    }
  end

  before do
    allow(http_client).to receive(:request)
      .with(method: :get, path: '/collectors')
      .and_return(collectors_response)
  end

  describe '#list' do
    it 'returns all collectors when no filters given' do
      result = collector.list
      expect(result.size).to eq(4)
    end

    it 'filters by name with query' do
      result = collector.list(query: 'web')
      expect(result.map { |c| c['id'] }).to eq(%w[1 3])
    end

    it 'filters by category with query' do
      result = collector.list(query: 'staging')
      expect(result.map { |c| c['id'] }).to eq(%w[3])
    end

    it 'is case-insensitive' do
      result = collector.list(query: 'PROD')
      expect(result.map { |c| c['id'] }).to eq(%w[1 2])
    end

    it 'limits results' do
      result = collector.list(limit: 2)
      expect(result.size).to eq(2)
    end

    it 'applies query before limit' do
      result = collector.list(query: 'prod', limit: 1)
      expect(result.size).to eq(1)
      expect(result.first['name']).to eq('prod-web-01')
    end

    it 'handles empty response' do
      allow(http_client).to receive(:request).and_return({ 'collectors' => [] })
      result = collector.list(query: 'anything')
      expect(result).to eq([])
    end

    it 'raises Error on failure' do
      allow(http_client).to receive(:request).and_raise(StandardError, 'network error')
      expect { collector.list }.to raise_error(Sumologic::Error, /Failed to list collectors/)
    end
  end
end
