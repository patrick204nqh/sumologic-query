# frozen_string_literal: true

require_relative 'sumologic/version'

module Sumologic
  # Base error class for all Sumologic errors
  class Error < StandardError; end

  # Authentication-related errors
  class AuthenticationError < Error; end

  # Timeout errors during search job execution
  class TimeoutError < Error; end
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
require_relative 'sumologic/search/job'

# Load metadata domain
require_relative 'sumologic/metadata/collector'
require_relative 'sumologic/metadata/collector_source_fetcher'
require_relative 'sumologic/metadata/source'

# Load main client (facade)
require_relative 'sumologic/client'

# Load CLI (requires thor gem)
begin
  require 'thor'
  require_relative 'sumologic/cli'
rescue LoadError
  # Thor not available - CLI won't work but library will
end
