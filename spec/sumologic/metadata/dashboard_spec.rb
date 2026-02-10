# frozen_string_literal: true

RSpec.describe Sumologic::Metadata::Dashboard do
  let(:http_client) { instance_double('Sumologic::Http::Client') }
  let(:dashboard) { described_class.new(http_client: http_client) }

  describe '#list' do
    it 'returns dashboards from v2 API' do
      response = {
        'dashboards' => [
          { 'id' => '1', 'title' => 'Prod Errors', 'domain' => 'aws' },
          { 'id' => '2', 'title' => 'Latency', 'theme' => 'Dark' }
        ],
        'next' => nil
      }

      allow(http_client).to receive(:request)
        .with(method: :get, path: '/dashboards', query_params: { limit: 100 })
        .and_return(response)

      result = dashboard.list
      expect(result.size).to eq(2)
      expect(result.first['title']).to eq('Prod Errors')
      expect(result.first['domain']).to eq('aws')
    end

    it 'paginates through multiple pages' do
      page1 = {
        'dashboards' => [{ 'id' => '1', 'title' => 'First' }],
        'next' => 'token123'
      }
      page2 = {
        'dashboards' => [{ 'id' => '2', 'title' => 'Second' }],
        'next' => nil
      }

      allow(http_client).to receive(:request)
        .with(method: :get, path: '/dashboards', query_params: { limit: 100 })
        .and_return(page1)
      allow(http_client).to receive(:request)
        .with(method: :get, path: '/dashboards', query_params: { limit: 99, token: 'token123' })
        .and_return(page2)

      result = dashboard.list
      expect(result.size).to eq(2)
    end

    it 'respects the limit parameter' do
      response = {
        'dashboards' => [
          { 'id' => '1', 'title' => 'First' },
          { 'id' => '2', 'title' => 'Second' },
          { 'id' => '3', 'title' => 'Third' }
        ],
        'next' => nil
      }

      allow(http_client).to receive(:request)
        .with(method: :get, path: '/dashboards', query_params: { limit: 2 })
        .and_return(response)

      result = dashboard.list(limit: 2)
      expect(result.size).to eq(2)
    end

    it 'raises Error on failure' do
      allow(http_client).to receive(:request).and_raise(StandardError, 'connection failed')

      expect { dashboard.list }.to raise_error(Sumologic::Error, /Failed to list dashboards/)
    end
  end

  describe '#get' do
    it 'returns a specific dashboard' do
      response = {
        'id' => 'abc123',
        'title' => 'My Dashboard',
        'panels' => [{ 'id' => 'panel1' }],
        'theme' => 'Light'
      }

      allow(http_client).to receive(:request)
        .with(method: :get, path: '/dashboards/abc123')
        .and_return(response)

      result = dashboard.get('abc123')
      expect(result['title']).to eq('My Dashboard')
      expect(result['panels'].size).to eq(1)
    end

    it 'raises Error on failure' do
      allow(http_client).to receive(:request).and_raise(StandardError, 'not found')

      expect { dashboard.get('bad_id') }.to raise_error(Sumologic::Error, /Failed to get dashboard bad_id/)
    end
  end

  describe '#search' do
    it 'filters dashboards by title' do
      response = {
        'dashboards' => [
          { 'id' => '1', 'title' => 'Prod Errors Dashboard' },
          { 'id' => '2', 'title' => 'Dev Latency' },
          { 'id' => '3', 'title' => 'prod metrics' }
        ],
        'next' => nil
      }

      allow(http_client).to receive(:request).and_return(response)

      result = dashboard.search(query: 'prod')
      expect(result.size).to eq(2)
      expect(result.map { |d| d['id'] }).to contain_exactly('1', '3')
    end
  end

  describe '#list_by_folder' do
    it 'filters dashboards by folder ID' do
      response = {
        'dashboards' => [
          { 'id' => '1', 'title' => 'A', 'folderId' => 'folder1' },
          { 'id' => '2', 'title' => 'B', 'folderId' => 'folder2' },
          { 'id' => '3', 'title' => 'C', 'folderId' => 'folder1' }
        ],
        'next' => nil
      }

      allow(http_client).to receive(:request).and_return(response)

      result = dashboard.list_by_folder(folder_id: 'folder1')
      expect(result.size).to eq(2)
    end
  end
end
