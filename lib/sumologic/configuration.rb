# frozen_string_literal: true

module Sumologic
  # Centralized configuration for Sumo Logic client
  class Configuration
    attr_accessor :access_id, :access_key, :deployment, :timeout, :initial_poll_interval, :max_poll_interval,
                  :poll_backoff_factor, :max_messages_per_request, :enable_parallel_pagination

    API_VERSION = 'v1'

    def initialize
      # Authentication
      @access_id = ENV.fetch('SUMO_ACCESS_ID', nil)
      @access_key = ENV.fetch('SUMO_ACCESS_KEY', nil)
      @deployment = ENV['SUMO_DEPLOYMENT'] || 'us2'

      # Search job polling
      @initial_poll_interval = 5 # seconds - start fast for small queries
      @max_poll_interval = 20 # seconds - slow down for large queries
      @poll_backoff_factor = 1.5 # increase interval by 50% each time

      # Timeouts and limits
      @timeout = 300 # seconds (5 minutes)
      @max_messages_per_request = 10_000

      # Performance options
      # Parallel pagination enabled by default for better performance
      # Uses connection pooling for thread-safe concurrent requests
      @enable_parallel_pagination = true
    end

    def base_url
      @base_url ||= build_base_url
    end

    def validate!
      raise AuthenticationError, 'SUMO_ACCESS_ID not set' unless @access_id
      raise AuthenticationError, 'SUMO_ACCESS_KEY not set' unless @access_key
    end

    private

    def build_base_url
      case @deployment
      when /^http/
        @deployment # Full URL provided
      when 'us1'
        "https://api.sumologic.com/api/#{API_VERSION}"
      when 'us2'
        "https://api.us2.sumologic.com/api/#{API_VERSION}"
      when 'eu'
        "https://api.eu.sumologic.com/api/#{API_VERSION}"
      when 'au'
        "https://api.au.sumologic.com/api/#{API_VERSION}"
      else
        "https://api.#{@deployment}.sumologic.com/api/#{API_VERSION}"
      end
    end
  end
end
