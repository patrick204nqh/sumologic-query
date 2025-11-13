# frozen_string_literal: true

require_relative 'sumologic/version'
require_relative 'sumologic/client'

module Sumologic
  class Error < StandardError; end
  class TimeoutError < Error; end
  class AuthenticationError < Error; end
end
