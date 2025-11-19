# frozen_string_literal: true

require 'time'

module Sumologic
  module Utils
    # Parses various time formats into ISO 8601 strings for the Sumo Logic API
    # Supports:
    # - 'now' - current time
    # - Relative times: '-30s', '-5m', '-2h', '-7d', '-1w', '-1M'
    # - Unix timestamps: '1700000000' or 1700000000
    # - ISO 8601: '2025-11-13T14:00:00'
    class TimeParser
      # Time unit multipliers in seconds
      UNITS = {
        's' => 1,           # seconds
        'm' => 60,          # minutes
        'h' => 3600,        # hours
        'd' => 86_400,       # days
        'w' => 604_800,      # weeks (7 days)
        'M' => 2_592_000 # months (30 days approximation)
      }.freeze

      RELATIVE_TIME_REGEX = /^([+-])(\d+)([smhdwM])$/.freeze

      class ParseError < StandardError; end

      # Parse a time string into ISO 8601 format
      # @param time_str [String, Integer] Time string or Unix timestamp
      # @param _timezone [String] IANA timezone name (default: 'UTC') - Reserved for future use
      # @return [String] ISO 8601 formatted time string
      def self.parse(time_str, _timezone: 'UTC')
        return parse_now if time_str.to_s.downcase == 'now'

        # Try relative time format (e.g., '-30m', '+1h')
        if time_str.is_a?(String) && (match = time_str.match(RELATIVE_TIME_REGEX))
          return parse_relative_time(match)
        end

        # Try Unix timestamp (integer or numeric string)
        return parse_unix_timestamp(time_str) if unix_timestamp?(time_str)

        # Try ISO 8601 format
        begin
          # Parse in UTC context to avoid local timezone conversion
          parsed = Time.parse(time_str.to_s)
          # If the input doesn't have timezone info, treat it as UTC
          parsed = parsed.getutc unless time_str.to_s.match?(/Z|[+-]\d{2}:?\d{2}$/)
          format_time(parsed)
        rescue ArgumentError
          raise ParseError,
                "Invalid time format: '#{time_str}'. " \
                "Supported formats: 'now', relative (e.g., '-30m'), Unix timestamp, or ISO 8601"
        end
      end

      # Parse timezone string to standard format
      # Accepts IANA names, offset formats, or common abbreviations
      # @param timezone_str [String] Timezone string
      # @return [String] Standardized timezone string
      def self.parse_timezone(timezone_str)
        return 'UTC' if timezone_str.nil? || timezone_str.empty?

        # Handle offset formats like "+00:00", "-05:00", "+0000"
        if timezone_str.match?(/^[+-]\d{2}:?\d{2}$/)
          # Normalize to format with colon
          normalized = timezone_str.sub(/^([+-]\d{2})(\d{2})$/, '\1:\2')
          return normalized
        end

        # Map common abbreviations to IANA names
        timezone_map = {
          # US timezones
          'EST' => 'America/New_York',
          'EDT' => 'America/New_York',
          'CST' => 'America/Chicago',
          'CDT' => 'America/Chicago',
          'MST' => 'America/Denver',
          'MDT' => 'America/Denver',
          'PST' => 'America/Los_Angeles',
          'PDT' => 'America/Los_Angeles',
          # Australian timezones
          'AEST' => 'Australia/Sydney',      # Australian Eastern Standard Time
          'AEDT' => 'Australia/Sydney',      # Australian Eastern Daylight Time
          'ACST' => 'Australia/Adelaide',    # Australian Central Standard Time
          'ACDT' => 'Australia/Adelaide',    # Australian Central Daylight Time
          'AWST' => 'Australia/Perth',       # Australian Western Standard Time
          'AWDT' => 'Australia/Perth'        # Australian Western Daylight Time (rarely used)
        }

        timezone_map[timezone_str.upcase] || timezone_str
      end

      private_class_method def self.parse_now
        format_time(Time.now)
      end

      private_class_method def self.parse_relative_time(match)
        sign, amount, unit = match.captures
        amount = amount.to_i
        amount = -amount if sign == '-'

        seconds_delta = amount * UNITS[unit]
        target_time = Time.now + seconds_delta

        format_time(target_time)
      end

      private_class_method def self.parse_unix_timestamp(timestamp)
        timestamp_int = timestamp.to_i

        # Handle millisecond timestamps (13 digits) - convert to seconds
        timestamp_int /= 1000 if timestamp.to_s.length == 13

        # Validate reasonable range (between year 2000 and 2100)
        min_timestamp = 946_684_800 # 2000-01-01
        max_timestamp = 4_102_444_800 # 2100-01-01

        unless timestamp_int.between?(min_timestamp, max_timestamp)
          raise ParseError, "Unix timestamp out of reasonable range: #{timestamp}"
        end

        time = Time.at(timestamp_int).utc
        format_time(time)
      end

      private_class_method def self.unix_timestamp?(value)
        # Check if it's an integer or a string that looks like a Unix timestamp
        # Unix timestamps are typically 10 digits (seconds) or 13 digits (milliseconds)
        return true if value.is_a?(Integer) && value.to_s.length.between?(10, 13)

        if value.is_a?(String)
          # Must be all digits, and between 10-13 characters
          return value.match?(/^\d{10,13}$/)
        end

        false
      end

      private_class_method def self.format_time(time)
        # Format as ISO 8601 without timezone suffix
        # Sumo Logic API expects format like "2025-11-13T14:00:00"
        time.utc.strftime('%Y-%m-%dT%H:%M:%S')
      end
    end
  end
end
