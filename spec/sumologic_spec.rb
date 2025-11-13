# frozen_string_literal: true

RSpec.describe Sumologic do
  it 'has a version number' do
    expect(Sumologic::VERSION).not_to be nil
  end

  it 'defines Error exception' do
    expect(Sumologic::Error).to be < StandardError
  end

  it 'defines TimeoutError exception' do
    expect(Sumologic::TimeoutError).to be < Sumologic::Error
  end

  it 'defines AuthenticationError exception' do
    expect(Sumologic::AuthenticationError).to be < Sumologic::Error
  end
end
