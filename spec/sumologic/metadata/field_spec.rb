# frozen_string_literal: true

RSpec.describe Sumologic::Metadata::Field do
  let(:http_client) { instance_double('Sumologic::Http::Client') }
  let(:field) { described_class.new(http_client: http_client) }

  describe '#list' do
    it 'returns custom fields' do
      response = {
        'data' => [
          { 'fieldId' => '1', 'fieldName' => 'environment', 'dataType' => 'String', 'state' => 'Enabled' },
          { 'fieldId' => '2', 'fieldName' => 'service', 'dataType' => 'String', 'state' => 'Enabled' }
        ]
      }

      allow(http_client).to receive(:request)
        .with(method: :get, path: '/fields')
        .and_return(response)

      result = field.list
      expect(result.size).to eq(2)
      expect(result.first['fieldName']).to eq('environment')
    end

    it 'raises Error on failure' do
      allow(http_client).to receive(:request).and_raise(StandardError, 'forbidden')

      expect { field.list }.to raise_error(Sumologic::Error, /Failed to list fields/)
    end
  end

  describe '#list_builtin' do
    it 'returns built-in fields' do
      response = {
        'data' => [
          { 'fieldId' => 'b1', 'fieldName' => '_sourceCategory', 'dataType' => 'String', 'state' => 'Enabled' },
          { 'fieldId' => 'b2', 'fieldName' => '_sourceHost', 'dataType' => 'String', 'state' => 'Enabled' }
        ]
      }

      allow(http_client).to receive(:request)
        .with(method: :get, path: '/fields/builtin')
        .and_return(response)

      result = field.list_builtin
      expect(result.size).to eq(2)
      expect(result.first['fieldName']).to eq('_sourceCategory')
    end

    it 'raises Error on failure' do
      allow(http_client).to receive(:request).and_raise(StandardError, 'timeout')

      expect { field.list_builtin }.to raise_error(Sumologic::Error, /Failed to list built-in fields/)
    end
  end
end
