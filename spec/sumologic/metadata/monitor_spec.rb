# frozen_string_literal: true

RSpec.describe Sumologic::Metadata::Monitor do
  let(:http_client) { instance_double('Sumologic::Http::Client') }
  let(:monitor) { described_class.new(http_client: http_client) }

  describe '#list' do
    let(:search_response) do
      [
        {
          'item' => {
            'id' => '1',
            'name' => 'High Error Rate',
            'contentType' => 'Monitor',
            'monitorType' => 'Logs',
            'status' => ['Critical'],
            'isDisabled' => false
          },
          'path' => '/Monitor/Production/High Error Rate'
        },
        {
          'item' => {
            'id' => '2',
            'name' => 'CPU Usage',
            'contentType' => 'Monitor',
            'monitorType' => 'Metrics',
            'status' => ['Normal'],
            'isDisabled' => false
          },
          'path' => '/Monitor/Production/CPU Usage'
        }
      ]
    end

    it 'returns monitors from the search API' do
      allow(http_client).to receive(:request)
        .with(method: :get, path: '/monitors/search', query_params: { limit: 100, offset: 0, query: '' })
        .and_return(search_response)

      result = monitor.list
      expect(result.size).to eq(2)
      expect(result.first['name']).to eq('High Error Rate')
      expect(result.first['monitorType']).to eq('Logs')
      expect(result.first['path']).to eq('/Monitor/Production/High Error Rate')
    end

    it 'filters by status' do
      allow(http_client).to receive(:request)
        .with(method: :get, path: '/monitors/search',
              query_params: { limit: 100, offset: 0, query: 'monitorStatus:Critical' })
        .and_return([search_response.first])

      result = monitor.list(status: 'Critical')
      expect(result.size).to eq(1)
      expect(result.first['name']).to eq('High Error Rate')
    end

    it 'filters by query' do
      allow(http_client).to receive(:request)
        .with(method: :get, path: '/monitors/search',
              query_params: { limit: 100, offset: 0, query: 'prod' })
        .and_return(search_response)

      result = monitor.list(query: 'prod')
      expect(result.size).to eq(2)
    end

    it 'combines query and status filters' do
      allow(http_client).to receive(:request)
        .with(method: :get, path: '/monitors/search',
              query_params: { limit: 100, offset: 0, query: 'prod monitorStatus:Warning' })
        .and_return([])

      result = monitor.list(query: 'prod', status: 'Warning')
      expect(result).to be_empty
    end

    it 'validates status values' do
      expect { monitor.list(status: 'InvalidStatus') }
        .to raise_error(Sumologic::Error, /Invalid monitor status/)
    end

    it 'accepts all valid status values' do
      %w[Normal Critical Warning MissingData Disabled AllTriggered].each do |status|
        allow(http_client).to receive(:request).and_return([])
        expect { monitor.list(status: status) }.not_to raise_error
      end
    end

    it 'paginates through results' do
      page1 = (1..100).map do |i|
        { 'item' => { 'id' => i.to_s, 'name' => "Monitor #{i}", 'contentType' => 'Monitor' }, 'path' => "/#{i}" }
      end
      page2 = [
        { 'item' => { 'id' => '101', 'name' => 'Monitor 101', 'contentType' => 'Monitor' }, 'path' => '/101' }
      ]

      allow(http_client).to receive(:request)
        .with(method: :get, path: '/monitors/search', query_params: { limit: 100, offset: 0, query: '' })
        .and_return(page1)
      allow(http_client).to receive(:request)
        .with(method: :get, path: '/monitors/search', query_params: { limit: 100, offset: 100, query: '' })
        .and_return(page2)

      result = monitor.list(limit: 200)
      expect(result.size).to eq(101)
    end

    it 'excludes folders from results' do
      mixed_response = [
        { 'item' => { 'id' => '1', 'name' => 'A Monitor', 'contentType' => 'Monitor' }, 'path' => '/m' },
        { 'item' => { 'id' => '2', 'name' => 'A Folder', 'contentType' => 'Folder' }, 'path' => '/f' }
      ]

      allow(http_client).to receive(:request).and_return(mixed_response)

      result = monitor.list
      expect(result.size).to eq(1)
      expect(result.first['name']).to eq('A Monitor')
    end

    it 'raises Error on failure' do
      allow(http_client).to receive(:request).and_raise(StandardError, 'timeout')

      expect { monitor.list }.to raise_error(Sumologic::Error, /Failed to list monitors/)
    end
  end

  describe '#get' do
    it 'returns a specific monitor' do
      response = {
        'id' => 'abc123',
        'name' => 'Error Rate Monitor',
        'monitorType' => 'Logs',
        'queries' => [{ 'query' => 'error | count' }],
        'triggers' => [{ 'triggerType' => 'Critical' }]
      }

      allow(http_client).to receive(:request)
        .with(method: :get, path: '/monitors/abc123')
        .and_return(response)

      result = monitor.get('abc123')
      expect(result['name']).to eq('Error Rate Monitor')
      expect(result['queries'].size).to eq(1)
    end

    it 'raises Error on failure' do
      allow(http_client).to receive(:request).and_raise(StandardError, 'not found')

      expect { monitor.get('bad_id') }.to raise_error(Sumologic::Error, /Failed to get monitor bad_id/)
    end
  end
end
