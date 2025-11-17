# frozen_string_literal: true

require 'spec_helper'
require 'sumologic/http/debug_logger'

RSpec.describe Sumologic::Http::DebugLogger do
  let(:uri) { URI('https://api.sumologic.com/api/v1/search/jobs') }
  let(:body) { { query: 'error', from: '2025-01-01', to: '2025-01-02' } }
  let(:response) { double('response', code: '200', message: 'OK', body: '{"status":"success"}') }

  describe '.log_request' do
    context 'when $DEBUG is true' do
      before { $DEBUG = true }
      after { $DEBUG = false }

      it 'logs request details' do
        expect { described_class.log_request(:post, uri, body) }.to output(
          /\[DEBUG\] API Request:.*Method: POST.*URL:.*Body:/m
        ).to_stderr
      end
    end

    context 'when $DEBUG is false' do
      before { $DEBUG = false }

      it 'does not log request details' do
        expect { described_class.log_request(:post, uri, body) }.not_to output.to_stderr
      end
    end
  end

  describe '.log_response' do
    context 'when $DEBUG is true' do
      before { $DEBUG = true }
      after { $DEBUG = false }

      it 'logs response details' do
        expect { described_class.log_response(response) }.to output(
          /\[DEBUG\] API Response:.*Status: 200 OK.*Body:/m
        ).to_stderr
      end
    end

    context 'when $DEBUG is false' do
      before { $DEBUG = false }

      it 'does not log response details' do
        expect { described_class.log_response(response) }.not_to output.to_stderr
      end
    end

    context 'when response body is long' do
      let(:long_body) { 'a' * 1000 }
      let(:long_response) { double('response', code: '200', message: 'OK', body: long_body) }

      before { $DEBUG = true }
      after { $DEBUG = false }

      it 'truncates the body' do
        expect { described_class.log_response(long_response) }.to output(
          /truncated, full length: 1000 characters/
        ).to_stderr
      end
    end
  end
end
