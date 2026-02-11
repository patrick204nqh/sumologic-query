# frozen_string_literal: true

RSpec.describe Sumologic::Metadata::SourceMetadata do
  let(:model) do
    described_class.new(
      name: 'ecs/my-service',
      category: 'aws/ecs/production',
      message_count: 1500
    )
  end

  describe '#to_h' do
    it 'includes all fields' do
      hash = model.to_h
      expect(hash['name']).to eq('ecs/my-service')
      expect(hash['category']).to eq('aws/ecs/production')
      expect(hash['message_count']).to eq(1500)
    end

    it 'omits nil values' do
      sparse = described_class.new(name: 'test', category: nil, message_count: 0)
      hash = sparse.to_h
      expect(hash.keys).to contain_exactly('name', 'message_count')
    end
  end

  describe '#<=>' do
    it 'sorts by message count descending' do
      high = described_class.new(name: 'a', category: 'cat', message_count: 1000)
      low = described_class.new(name: 'b', category: 'cat', message_count: 100)
      sorted = [low, high].sort
      expect(sorted.map(&:name)).to eq(%w[a b])
    end
  end
end
