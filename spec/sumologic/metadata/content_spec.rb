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
end
