# frozen_string_literal: true

RSpec.describe Sumologic::Metadata::DashboardModel do
  let(:data) do
    {
      'id' => 'dash123',
      'title' => 'Production Errors',
      'description' => 'Error monitoring',
      'folderId' => 'folder456',
      'domain' => 'aws',
      'refreshInterval' => 300,
      'theme' => 'Dark',
      'contentId' => 'content789',
      'panels' => [{ 'id' => 'panel1' }],
      'layout' => { 'layoutType' => 'Grid' }
    }
  end

  let(:model) { described_class.new(data) }

  describe '#to_h' do
    it 'includes v2 fields' do
      hash = model.to_h
      expect(hash['id']).to eq('dash123')
      expect(hash['title']).to eq('Production Errors')
      expect(hash['description']).to eq('Error monitoring')
      expect(hash['folderId']).to eq('folder456')
      expect(hash['domain']).to eq('aws')
      expect(hash['refreshInterval']).to eq(300)
      expect(hash['theme']).to eq('Dark')
      expect(hash['contentId']).to eq('content789')
    end

    it 'omits nil values' do
      sparse_model = described_class.new({ 'id' => '1', 'title' => 'Minimal' })
      hash = sparse_model.to_h
      expect(hash.keys).to contain_exactly('id', 'title')
    end
  end

  describe '#to_full_h' do
    it 'returns the full raw API data' do
      full = model.to_full_h
      expect(full['panels']).to eq([{ 'id' => 'panel1' }])
      expect(full['layout']).to eq({ 'layoutType' => 'Grid' })
    end
  end
end
