# frozen_string_literal: true

RSpec.describe Sumologic::Metadata::Content do
  let(:http_client) { instance_double('Sumologic::Http::Client') }
  let(:content) { described_class.new(http_client: http_client) }

  describe '#get_by_path' do
    it 'returns content item for a valid path' do
      response = {
        'id' => 'content123',
        'name' => 'My Saved Search',
        'itemType' => 'Search',
        'parentId' => 'folder456',
        'createdAt' => '2025-01-01T00:00:00Z',
        'createdBy' => 'user789'
      }

      allow(http_client).to receive(:request)
        .with(method: :get, path: '/content/path', query_params: { path: '/Library/Users/me/My Saved Search' })
        .and_return(response)

      result = content.get_by_path('/Library/Users/me/My Saved Search')
      expect(result['id']).to eq('content123')
      expect(result['name']).to eq('My Saved Search')
      expect(result['itemType']).to eq('Search')
      expect(result['parentId']).to eq('folder456')
    end

    it 'raises Error for invalid path' do
      allow(http_client).to receive(:request).and_raise(StandardError, 'not found')

      expect { content.get_by_path('/Library/Invalid/Path') }
        .to raise_error(Sumologic::Error, /Failed to get content at path/)
    end
  end

  describe '#export' do
    it 'runs the full async export lifecycle' do
      # Start export job
      allow(http_client).to receive(:request)
        .with(method: :post, path: '/content/abc123/export')
        .and_return({ 'id' => 'job456' })

      # Poll status - returns Success immediately
      allow(http_client).to receive(:request)
        .with(method: :get, path: '/content/abc123/export/job456/status')
        .and_return({ 'status' => 'Success' })

      # Fetch result
      exported_content = { 'type' => 'SavedSearchWithScheduleSyncDefinition', 'name' => 'My Search' }
      allow(http_client).to receive(:request)
        .with(method: :get, path: '/content/abc123/export/job456/result')
        .and_return(exported_content)

      result = content.export('abc123')
      expect(result['name']).to eq('My Search')
    end

    it 'polls until export completes' do
      allow(http_client).to receive(:request)
        .with(method: :post, path: '/content/abc123/export')
        .and_return({ 'id' => 'job456' })

      # First poll: InProgress, second: Success
      call_count = 0
      allow(http_client).to receive(:request)
        .with(method: :get, path: '/content/abc123/export/job456/status') do
        call_count += 1
        { 'status' => call_count >= 2 ? 'Success' : 'InProgress' }
      end

      allow(http_client).to receive(:request)
        .with(method: :get, path: '/content/abc123/export/job456/result')
        .and_return({ 'name' => 'Done' })

      # Stub sleep to avoid waiting
      allow(content).to receive(:sleep)

      result = content.export('abc123')
      expect(result['name']).to eq('Done')
      expect(call_count).to be >= 2
    end

    it 'raises Error when export job fails' do
      allow(http_client).to receive(:request)
        .with(method: :post, path: '/content/bad/export')
        .and_return({ 'id' => 'job789' })

      allow(http_client).to receive(:request)
        .with(method: :get, path: '/content/bad/export/job789/status')
        .and_return({ 'status' => 'Failed', 'error' => { 'message' => 'content not found' } })

      expect { content.export('bad') }
        .to raise_error(Sumologic::Error, /Failed to export content bad/)
    end

    it 'raises Error on network failure' do
      allow(http_client).to receive(:request).and_raise(StandardError, 'connection refused')

      expect { content.export('abc123') }
        .to raise_error(Sumologic::Error, /Failed to export content abc123/)
    end
  end
end
