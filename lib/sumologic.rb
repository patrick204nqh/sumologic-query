# frozen_string_literal: true

require_relative 'sumologic/version'

module Sumologic
  # Base error class for all Sumologic errors
  class Error < StandardError; end

  # Authentication-related errors
  class AuthenticationError < Error; end

  # Timeout errors during search job execution
  class TimeoutError < Error; end

  # Rate limit errors (429 responses)
  # Includes retry_after when available from X-RateLimit-Reset or Retry-After headers
  class RateLimitError < Error
    attr_reader :retry_after, :limit, :remaining, :reset_at

    def initialize(message, retry_after: nil, limit: nil, remaining: nil, reset_at: nil)
      super(message)
      @retry_after = retry_after
      @limit = limit
      @remaining = remaining
      @reset_at = reset_at
    end
  end
end

# Load configuration first
require_relative 'sumologic/configuration'

# Load HTTP layer
require_relative 'sumologic/http/authenticator'
require_relative 'sumologic/http/client'

# Load utilities
require_relative 'sumologic/utils/worker'

# Load search domain
require_relative 'sumologic/search/poller'
require_relative 'sumologic/search/message_fetcher'
require_relative 'sumologic/search/record_fetcher'
require_relative 'sumologic/search/job'

# Load metadata domain
require_relative 'sumologic/metadata/loggable'
require_relative 'sumologic/metadata/models'
require_relative 'sumologic/metadata/collector'
require_relative 'sumologic/metadata/collector_source_fetcher'
require_relative 'sumologic/metadata/source'
require_relative 'sumologic/metadata/dynamic_source_discovery'
require_relative 'sumologic/metadata/monitor'
require_relative 'sumologic/metadata/folder'
require_relative 'sumologic/metadata/dashboard'
require_relative 'sumologic/metadata/health_event'
require_relative 'sumologic/metadata/field'
require_relative 'sumologic/metadata/lookup_table'
require_relative 'sumologic/metadata/app'

# Load main client (facade)
require_relative 'sumologic/client'

# Load CLI (requires thor gem)
begin
  require 'thor'
  require_relative 'sumologic/cli'
rescue LoadError
  # Thor not available - CLI won't work but library will
end
