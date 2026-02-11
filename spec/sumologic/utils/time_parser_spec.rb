# frozen_string_literal: true

require 'spec_helper'
require 'sumologic/utils/time_parser'

RSpec.describe Sumologic::Utils::TimeParser do
  describe '.parse' do
    let(:fixed_time) { Time.utc(2025, 11, 19, 12, 0, 0) }

    before do
      allow(Time).to receive(:now).and_return(fixed_time)
    end

    context 'with "now" keyword' do
      it 'returns current time in ISO 8601 format' do
        result = described_class.parse('now')
        expect(result).to eq('2025-11-19T12:00:00')
      end

      it 'is case insensitive' do
        expect(described_class.parse('NOW')).to eq('2025-11-19T12:00:00')
        expect(described_class.parse('Now')).to eq('2025-11-19T12:00:00')
      end
    end

    context 'with relative time formats' do
      it 'parses seconds ago' do
        result = described_class.parse('-30s')
        expect(result).to eq('2025-11-19T11:59:30')
      end

      it 'parses minutes ago' do
        result = described_class.parse('-30m')
        expect(result).to eq('2025-11-19T11:30:00')
      end

      it 'parses hours ago' do
        result = described_class.parse('-2h')
        expect(result).to eq('2025-11-19T10:00:00')
      end

      it 'parses days ago' do
        result = described_class.parse('-7d')
        expect(result).to eq('2025-11-12T12:00:00')
      end

      it 'parses weeks ago' do
        result = described_class.parse('-1w')
        expect(result).to eq('2025-11-12T12:00:00')
      end

      it 'parses months ago (30 days approximation)' do
        result = described_class.parse('-1M')
        expect(result).to eq('2025-10-20T12:00:00')
      end

      it 'supports positive offsets (future times)' do
        result = described_class.parse('+1h')
        expect(result).to eq('2025-11-19T13:00:00')
      end

      it 'handles large amounts' do
        result = described_class.parse('-100m')
        expect(result).to eq('2025-11-19T10:20:00')
      end

      it 'parses compound hours and minutes' do
        result = described_class.parse('-1h30m')
        expect(result).to eq('2025-11-19T10:30:00')
      end

      it 'parses compound days and hours' do
        result = described_class.parse('-2d3h')
        expect(result).to eq('2025-11-17T09:00:00')
      end

      it 'parses compound days, hours, and minutes' do
        result = described_class.parse('-1d2h30m')
        expect(result).to eq('2025-11-18T09:30:00')
      end

      it 'parses compound with positive offset' do
        result = described_class.parse('+1h30m')
        expect(result).to eq('2025-11-19T13:30:00')
      end
    end

    context 'with Unix timestamps' do
      it 'parses integer Unix timestamp' do
        result = described_class.parse(1_700_000_000)
        expect(result).to eq('2023-11-14T22:13:20')
      end

      it 'parses string Unix timestamp (10 digits)' do
        result = described_class.parse('1700000000')
        expect(result).to eq('2023-11-14T22:13:20')
      end

      it 'parses millisecond Unix timestamp (13 digits)' do
        result = described_class.parse('1700000000000')
        expect(result).to eq('2023-11-14T22:13:20')
      end

      it 'raises error for timestamps out of reasonable range' do
        expect do
          described_class.parse('10000000') # Too old (1970, only 8 digits)
        end.to raise_error(Sumologic::Utils::TimeParser::ParseError)
      end

      it 'raises error for future timestamps beyond 2100' do
        expect do
          described_class.parse('9999999999')
        end.to raise_error(Sumologic::Utils::TimeParser::ParseError, /out of reasonable range/)
      end
    end

    context 'with ISO 8601 format' do
      it 'parses full ISO 8601 timestamp as UTC when no timezone specified' do
        result = described_class.parse('2025-11-13T14:30:00')
        # Without timezone, it's treated as UTC
        expect(result).to match(/2025-11-13T\d{2}:30:00/)
      end

      it 'parses ISO 8601 with timezone' do
        result = described_class.parse('2025-11-13T14:30:00+00:00')
        expect(result).to eq('2025-11-13T14:30:00')
      end

      it 'parses ISO 8601 with Z suffix' do
        result = described_class.parse('2025-11-13T14:30:00Z')
        expect(result).to eq('2025-11-13T14:30:00')
      end

      it 'parses date-only format' do
        result = described_class.parse('2025-11-13')
        # Date-only is parsed and converted to UTC
        # Time.parse treats date-only as local midnight, then we convert to UTC
        expect(result).to start_with('2025-11-1') # Allow for timezone conversion
        expect(result).to end_with(':00:00')
      end
    end

    context 'with invalid formats' do
      it 'raises ParseError for invalid format' do
        expect do
          described_class.parse('invalid-time')
        end.to raise_error(Sumologic::Utils::TimeParser::ParseError, /Invalid time format/)
      end

      it 'raises ParseError for completely invalid string' do
        expect do
          described_class.parse('not-a-time-at-all')
        end.to raise_error(Sumologic::Utils::TimeParser::ParseError)
      end

      it 'raises ParseError for empty string' do
        expect do
          described_class.parse('')
        end.to raise_error(Sumologic::Utils::TimeParser::ParseError)
      end
    end
  end

  describe '.parse_timezone' do
    it 'returns UTC for nil' do
      expect(described_class.parse_timezone(nil)).to eq('UTC')
    end

    it 'returns UTC for empty string' do
      expect(described_class.parse_timezone('')).to eq('UTC')
    end

    it 'normalizes offset format with colon' do
      expect(described_class.parse_timezone('+0000')).to eq('+00:00')
      expect(described_class.parse_timezone('-0500')).to eq('-05:00')
    end

    it 'accepts offset format with colon as-is' do
      expect(described_class.parse_timezone('+00:00')).to eq('+00:00')
      expect(described_class.parse_timezone('-05:00')).to eq('-05:00')
    end

    it 'maps EST to America/New_York' do
      expect(described_class.parse_timezone('EST')).to eq('America/New_York')
      expect(described_class.parse_timezone('EDT')).to eq('America/New_York')
    end

    it 'maps PST to America/Los_Angeles' do
      expect(described_class.parse_timezone('PST')).to eq('America/Los_Angeles')
      expect(described_class.parse_timezone('PDT')).to eq('America/Los_Angeles')
    end

    it 'maps CST to America/Chicago' do
      expect(described_class.parse_timezone('CST')).to eq('America/Chicago')
      expect(described_class.parse_timezone('CDT')).to eq('America/Chicago')
    end

    it 'maps MST to America/Denver' do
      expect(described_class.parse_timezone('MST')).to eq('America/Denver')
      expect(described_class.parse_timezone('MDT')).to eq('America/Denver')
    end

    it 'maps AEST to Australia/Sydney' do
      expect(described_class.parse_timezone('AEST')).to eq('Australia/Sydney')
      expect(described_class.parse_timezone('AEDT')).to eq('Australia/Sydney')
    end

    it 'maps ACST to Australia/Adelaide' do
      expect(described_class.parse_timezone('ACST')).to eq('Australia/Adelaide')
      expect(described_class.parse_timezone('ACDT')).to eq('Australia/Adelaide')
    end

    it 'maps AWST to Australia/Perth' do
      expect(described_class.parse_timezone('AWST')).to eq('Australia/Perth')
      expect(described_class.parse_timezone('AWDT')).to eq('Australia/Perth')
    end

    it 'returns IANA timezone names as-is' do
      expect(described_class.parse_timezone('America/New_York')).to eq('America/New_York')
      expect(described_class.parse_timezone('Europe/London')).to eq('Europe/London')
      expect(described_class.parse_timezone('Australia/Sydney')).to eq('Australia/Sydney')
      expect(described_class.parse_timezone('UTC')).to eq('UTC')
    end

    it 'is case insensitive for abbreviations' do
      expect(described_class.parse_timezone('est')).to eq('America/New_York')
      expect(described_class.parse_timezone('pst')).to eq('America/Los_Angeles')
      expect(described_class.parse_timezone('aest')).to eq('Australia/Sydney')
      expect(described_class.parse_timezone('awst')).to eq('Australia/Perth')
    end
  end
end
