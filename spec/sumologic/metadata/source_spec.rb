# frozen_string_literal: true

RSpec.describe Sumologic::Metadata::Source do
  let(:http_client) { instance_double('Sumologic::Http::Client') }
  let(:collector_client) { instance_double(Sumologic::Metadata::Collector) }
  let(:config) { instance_double(Sumologic::Configuration, max_workers: 1, request_delay: 0) }
  let(:source) { described_class.new(http_client: http_client, collector_client: collector_client, config: config) }

  let(:collectors) do
    [
      { 'id' => '1', 'name' => 'prod-web-01', 'alive' => true },
      { 'id' => '2', 'name' => 'prod-api-01', 'alive' => true },
      { 'id' => '3', 'name' => 'staging-web-01', 'alive' => true },
      { 'id' => '4', 'name' => 'dead-collector', 'alive' => false }
    ]
  end

  let(:web_sources) do
    {
      'sources' => [
        { 'id' => 's1', 'name' => 'nginx_access', 'category' => 'production/web' },
        { 'id' => 's2', 'name' => 'nginx_error', 'category' => 'production/web' }
      ]
    }
  end

  let(:api_sources) do
    {
      'sources' => [
        { 'id' => 's3', 'name' => 'app_logs', 'category' => 'production/api' }
      ]
    }
  end

  let(:staging_sources) do
    {
      'sources' => [
        { 'id' => 's4', 'name' => 'nginx_access', 'category' => 'staging/web' }
      ]
    }
  end

  before do
    allow(collector_client).to receive(:list).and_return(collectors)
  end

  describe '#list' do
    it 'returns sources for a specific collector' do
      allow(http_client).to receive(:request)
        .with(method: :get, path: '/collectors/1/sources')
        .and_return(web_sources)

      result = source.list(collector_id: '1')
      expect(result.size).to eq(2)
    end

    it 'raises Error on failure' do
      allow(http_client).to receive(:request).and_raise(StandardError, 'timeout')
      expect { source.list(collector_id: '1') }.to raise_error(Sumologic::Error, /Failed to list sources/)
    end
  end

  describe '#list_all' do
    before do
      allow(http_client).to receive(:request)
        .with(method: :get, path: '/collectors/1/sources').and_return(web_sources)
      allow(http_client).to receive(:request)
        .with(method: :get, path: '/collectors/2/sources').and_return(api_sources)
      allow(http_client).to receive(:request)
        .with(method: :get, path: '/collectors/3/sources').and_return(staging_sources)
    end

    it 'returns sources from all active collectors' do
      result = source.list_all
      expect(result.size).to eq(3)
      total_sources = result.sum { |r| r['sources'].size }
      expect(total_sources).to eq(4)
    end

    it 'skips dead collectors' do
      result = source.list_all
      collector_ids = result.map { |r| r['collector']['id'] }
      expect(collector_ids).not_to include('4')
    end

    it 'filters collectors by name' do
      result = source.list_all(collector: 'web')
      collector_names = result.map { |r| r['collector']['name'] }
      expect(collector_names).to eq(%w[prod-web-01 staging-web-01])
    end

    it 'filters sources by name' do
      result = source.list_all(name: 'nginx')
      sources = result.flat_map { |r| r['sources'] }
      expect(sources.map { |s| s['id'] }).to eq(%w[s1 s2 s4])
    end

    it 'filters sources by category' do
      result = source.list_all(category: 'staging')
      expect(result.size).to eq(1)
      expect(result.first['collector']['name']).to eq('staging-web-01')
    end

    it 'combines collector and source filters' do
      result = source.list_all(collector: 'prod', name: 'nginx')
      sources = result.flat_map { |r| r['sources'] }
      expect(sources.map { |s| s['id'] }).to eq(%w[s1 s2])
    end

    it 'limits total sources across collectors' do
      result = source.list_all(limit: 2)
      total_sources = result.sum { |r| r['sources'].size }
      expect(total_sources).to eq(2)
    end

    it 'applies filters before limit' do
      result = source.list_all(name: 'nginx', limit: 1)
      total_sources = result.sum { |r| r['sources'].size }
      expect(total_sources).to eq(1)
      expect(result.first['sources'].first['id']).to eq('s1')
    end

    it 'excludes collectors with no matching sources after filtering' do
      result = source.list_all(name: 'app_logs')
      expect(result.size).to eq(1)
      expect(result.first['collector']['name']).to eq('prod-api-01')
    end
  end
end
