# frozen_string_literal: true

RSpec.describe Sumologic::Http::Authenticator do
  describe '#auth_header' do
    it 'generates correct Basic Auth header' do
      authenticator = described_class.new(
        access_id: 'test_id',
        access_key: 'test_key'
      )

      expected = "Basic #{Base64.strict_encode64('test_id:test_key')}"
      expect(authenticator.auth_header).to eq(expected)
    end

    it 'handles special characters in credentials' do
      authenticator = described_class.new(
        access_id: 'id+with/special=chars',
        access_key: 'key@with#special$chars'
      )

      # Should encode properly
      expect(authenticator.auth_header).to start_with('Basic ')
      expect(authenticator.auth_header.length).to be > 10
    end
  end
end
