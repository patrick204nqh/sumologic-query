# frozen_string_literal: true

require 'base64'

module Sumologic
  module Http
    # Handles authentication header generation for Sumo Logic API
    class Authenticator
      def initialize(access_id:, access_key:)
        @access_id = access_id
        @access_key = access_key
      end

      def auth_header
        encoded = Base64.strict_encode64("#{@access_id}:#{@access_key}")
        "Basic #{encoded}"
      end
    end
  end
end
