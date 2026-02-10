# frozen_string_literal: true

RSpec.describe Sumologic::Metadata::App do
  let(:http_client) { instance_double('Sumologic::Http::Client') }
  let(:app) { described_class.new(http_client: http_client) }

  describe '#list' do
    it 'returns apps from the catalog' do
      response = {
        'apps' => [
          { 'appId' => 'a1', 'appDefinition' => { 'name' => 'AWS CloudTrail', 'description' => 'Monitor AWS API calls' } },
          { 'appId' => 'a2', 'appDefinition' => { 'name' => 'Kubernetes', 'description' => 'Monitor K8s clusters' } }
        ]
      }

      allow(http_client).to receive(:request)
        .with(method: :get, path: '/apps')
        .and_return(response)

      result = app.list
      expect(result.size).to eq(2)
      expect(result.first['appDefinition']['name']).to eq('AWS CloudTrail')
    end

    it 'handles empty catalog' do
      allow(http_client).to receive(:request).and_return({ 'apps' => [] })

      result = app.list
      expect(result).to be_empty
    end

    it 'raises Error on failure' do
      allow(http_client).to receive(:request).and_raise(StandardError, 'forbidden')

      expect { app.list }.to raise_error(Sumologic::Error, /Failed to list apps/)
    end
  end
end
