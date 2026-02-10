# frozen_string_literal: true

RSpec.describe Sumologic::Metadata::HealthEvent do
  let(:http_client) { instance_double('Sumologic::Http::Client') }
  let(:health_event) { described_class.new(http_client: http_client) }

  describe '#list' do
    it 'returns health events' do
      response = {
        'data' => [
          { 'eventId' => '1', 'eventName' => 'CollectorOffline', 'severityLevel' => 'Error' },
          { 'eventId' => '2', 'eventName' => 'IngestBudgetExceeded', 'severityLevel' => 'Warning' }
        ]
      }

      allow(http_client).to receive(:request)
        .with(method: :get, path: '/healthEvents', query_params: { limit: 100 })
        .and_return(response)

      result = health_event.list
      expect(result.size).to eq(2)
      expect(result.first['eventName']).to eq('CollectorOffline')
    end

    it 'handles empty response' do
      allow(http_client).to receive(:request).and_return({ 'data' => [] })

      result = health_event.list
      expect(result).to be_empty
    end

    it 'raises Error on failure' do
      allow(http_client).to receive(:request).and_raise(StandardError, 'timeout')

      expect { health_event.list }.to raise_error(Sumologic::Error, /Failed to list health events/)
    end
  end
end
