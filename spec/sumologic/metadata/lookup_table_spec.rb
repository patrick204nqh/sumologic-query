# frozen_string_literal: true

RSpec.describe Sumologic::Metadata::LookupTable do
  let(:http_client) { instance_double('Sumologic::Http::Client') }
  let(:lookup_table) { described_class.new(http_client: http_client) }

  describe '#get' do
    it 'returns a specific lookup table' do
      response = {
        'id' => 'lt123',
        'name' => 'IP Allowlist',
        'description' => 'Known good IPs',
        'parentFolderId' => 'folder1',
        'fields' => [
          { 'fieldName' => 'ip', 'fieldType' => 'string' },
          { 'fieldName' => 'label', 'fieldType' => 'string' }
        ]
      }

      allow(http_client).to receive(:request)
        .with(method: :get, path: '/lookupTables/lt123')
        .and_return(response)

      result = lookup_table.get('lt123')
      expect(result['name']).to eq('IP Allowlist')
      expect(result['fields'].size).to eq(2)
    end

    it 'raises Error on failure' do
      allow(http_client).to receive(:request).and_raise(StandardError, 'not found')

      expect { lookup_table.get('bad_id') }.to raise_error(Sumologic::Error, /Failed to get lookup table bad_id/)
    end
  end
end
