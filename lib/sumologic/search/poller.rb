# frozen_string_literal: true

module Sumologic
  module Search
    # Handles adaptive polling of search jobs with exponential backoff
    class Poller
      def initialize(http_client:, config:)
        @http = http_client
        @config = config
      end

      # Poll until job completes or times out
      # Returns final job status data
      def poll(job_id)
        start_time = Time.now
        interval = @config.initial_poll_interval
        poll_count = 0

        loop do
          check_timeout!(start_time)

          data = fetch_job_status(job_id)
          state = data['state']

          log_poll_status(state, data, interval, poll_count)

          case state
          when 'DONE GATHERING RESULTS'
            log_completion(start_time, poll_count)
            return data
          when 'CANCELLED', 'FORCE PAUSED'
            raise Error, "Search job #{state.downcase}"
          end

          sleep interval
          poll_count += 1
          interval = calculate_next_interval(interval)
        end
      end

      private

      def check_timeout!(start_time)
        elapsed = Time.now - start_time
        return unless elapsed > @config.timeout

        raise TimeoutError, "Search job timed out after #{@config.timeout} seconds"
      end

      def fetch_job_status(job_id)
        @http.request(
          method: :get,
          path: "/search/jobs/#{job_id}"
        )
      end

      def calculate_next_interval(current_interval)
        # Adaptive backoff: gradually increase interval for long-running jobs
        new_interval = current_interval * @config.poll_backoff_factor
        [new_interval, @config.max_poll_interval].min
      end

      def log_poll_status(state, data, interval, count)
        msg_count = data['messageCount']
        rec_count = data['recordCount']
        log_info "Job state: #{state} (#{msg_count} messages, #{rec_count} records) " \
                 "[interval: #{interval}s, poll: #{count}]"
      end

      def log_completion(start_time, poll_count)
        elapsed = Time.now - start_time
        log_info "Job completed in #{elapsed.round(1)} seconds after #{poll_count + 1} polls"
      end

      def log_info(message)
        warn "[Sumologic::Search::Poller] #{message}" if ENV['SUMO_DEBUG'] || $DEBUG
      end
    end
  end
end
