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

  it 'defines RateLimitError exception' do
    expect(Sumologic::RateLimitError).to be < Sumologic::Error
  end

  describe Sumologic::RateLimitError do
    it 'stores retry_after value' do
      error = Sumologic::RateLimitError.new('Rate limited', retry_after: 30)
      expect(error.retry_after).to eq(30)
    end

    it 'stores rate limit info' do
      error = Sumologic::RateLimitError.new(
        'Rate limited',
        retry_after: 30,
        limit: 100,
        remaining: 0,
        reset_at: Time.now + 30
      )
      expect(error.limit).to eq(100)
      expect(error.remaining).to eq(0)
      expect(error.reset_at).to be_a(Time)
    end
  end
end
