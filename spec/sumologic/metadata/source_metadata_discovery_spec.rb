# frozen_string_literal: true

RSpec.describe Sumologic::Metadata::SourceMetadataDiscovery do
  let(:http_client) { instance_double('Sumologic::Http::Client') }
  let(:search_job) { instance_double(Sumologic::Search::Job) }
  let(:config) { instance_double(Sumologic::Configuration) }
  let(:discovery) { described_class.new(http_client: http_client, search_job: search_job, config: config) }

  let(:aggregation_records) do
    [
      { 'map' => { '_sourcename' => 'nginx_access', '_sourcecategory' => 'production/web', '_count' => '5000' } },
      { 'map' => { '_sourcename' => 'nginx_error', '_sourcecategory' => 'production/web', '_count' => '200' } },
      { 'map' => { '_sourcename' => 'app_logs', '_sourcecategory' => 'production/api', '_count' => '3000' } },
      { 'map' => { '_sourcename' => 'cloudwatch_lambda', '_sourcecategory' => 'aws/lambda', '_count' => '1500' } },
      { 'map' => { '_sourcename' => 'ecs_task', '_sourcecategory' => 'aws/ecs/nginx', '_count' => '800' } }
    ]
  end

  before do
    allow(search_job).to receive(:execute_aggregation).and_return(aggregation_records)
  end

  describe '#discover' do
    let(:base_params) { { from_time: '-24h', to_time: 'now', time_zone: 'UTC' } }

    it 'returns all sources when no keyword given' do
      result = discovery.discover(**base_params)
      expect(result['total_sources']).to eq(5)
      expect(result['keyword']).to be_nil
    end

    it 'filters by keyword matching source name' do
      result = discovery.discover(**base_params, keyword: 'nginx')
      names = result['sources'].map { |s| s['name'] }
      expect(names).to eq(%w[nginx_access ecs_task nginx_error])
    end

    it 'filters by keyword matching source category' do
      result = discovery.discover(**base_params, keyword: 'aws')
      names = result['sources'].map { |s| s['name'] }
      expect(names).to eq(%w[cloudwatch_lambda ecs_task])
    end

    it 'is case-insensitive' do
      result = discovery.discover(**base_params, keyword: 'NGINX')
      expect(result['total_sources']).to eq(3)
    end

    it 'limits results' do
      result = discovery.discover(**base_params, limit: 2)
      expect(result['total_sources']).to eq(2)
    end

    it 'applies keyword filter before limit' do
      result = discovery.discover(**base_params, keyword: 'nginx', limit: 1)
      expect(result['total_sources']).to eq(1)
      expect(result['sources'].first['name']).to eq('nginx_access')
    end

    it 'includes keyword in response' do
      result = discovery.discover(**base_params, keyword: 'nginx')
      expect(result['keyword']).to eq('nginx')
    end

    it 'returns empty when keyword matches nothing' do
      result = discovery.discover(**base_params, keyword: 'nonexistent')
      expect(result['total_sources']).to eq(0)
      expect(result['sources']).to eq([])
    end

    it 'raises Error on failure' do
      allow(search_job).to receive(:execute_aggregation).and_raise(StandardError, 'timeout')
      expect { discovery.discover(**base_params) }.to raise_error(Sumologic::Error, /Failed to discover/)
    end
  end
end
