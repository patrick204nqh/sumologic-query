# frozen_string_literal: true

require 'json'
require 'tempfile'
require 'time'
require 'open3'
require 'shellwords'

module Sumologic
  module Interactive
    class FzfViewer
      DELIMITER = '||'

      def initialize(results)
        @results = results
        @messages = results['messages'] || []
      end

      def run
        return if @messages.empty?

        Dir.mktmpdir('sumo-interactive') do |tmpdir|
          input_file = File.join(tmpdir, 'input.txt')
          preview_file = File.join(tmpdir, 'preview.jsonl')

          prepare_data(input_file, preview_file)
          selected = execute_fzf(input_file, preview_file)
          handle_selection(selected) unless selected.empty?
        end
      end

      private

      def prepare_data(input_file, preview_file)
        # Write data lines only (no header in file - handled by FZF --header)
        File.open(input_file, 'w') do |f|
          @messages.each do |msg|
            f.puts format_line(msg)
          end
        end

        # Write JSONL for preview (one JSON per line, line numbers match input)
        File.open(preview_file, 'w') do |f|
          @messages.each do |msg|
            f.puts JSON.generate(msg['map'])
          end
        end
      end

      def format_line(msg)
        map = msg['map']

        time = format_time(map['_messagetime'])
        level = format_level(map['level'] || map['severity'] || 'INFO')
        source = truncate(map['_sourceCategory'] || '-', 25)
        message = truncate(sanitize(map['_raw'] || map['message'] || ''), 80)

        # No index in display - use FZF line number instead
        "#{time} #{level} #{source.ljust(25)} #{message}"
      end

      def format_time(timestamp_ms)
        return 'N/A' unless timestamp_ms

        Time.at(timestamp_ms.to_i / 1000).strftime('%H:%M:%S')
      end

      def format_level(level)
        level_str = level.to_s.upcase.ljust(7)

        case level_str.strip
        when 'ERROR', 'FATAL', 'CRITICAL'
          "\e[31m#{level_str}\e[0m"  # Red
        when 'WARN', 'WARNING'
          "\e[33m#{level_str}\e[0m"  # Yellow
        when 'INFO'
          "\e[36m#{level_str}\e[0m"  # Cyan
        when 'DEBUG', 'TRACE'
          "\e[90m#{level_str}\e[0m"  # Gray
        else
          level_str
        end
      end

      def sanitize(text)
        text.to_s.gsub(/[\n\r\t]/, ' ').squeeze(' ')
      end

      def truncate(text, length)
        text = text.to_s
        text.length > length ? "#{text[0...(length - 3)]}..." : text
      end

      def colorize_json(data)
        JSON.pretty_generate(data)
      end

      def execute_fzf(input_path, preview_path)
        fzf_args = build_fzf_args(input_path, preview_path)

        # Use IO.popen with array to avoid shell escaping issues
        result = IO.popen(fzf_args, 'r+') do |io|
          File.readlines(input_path).each { |line| io.puts line }
          io.close_write
          io.read
        end

        result.strip
      end

      def build_fzf_args(input_path, preview_path)
        preview_cmd = build_preview_command(preview_path)
        view_cmd = build_view_command(preview_path)
        header_text = build_header_text

        [
          'fzf',
          '--ansi',
          '--multi',
          "--header=#{header_text}",
          "--preview=#{preview_cmd}",
          '--preview-window=right:60%:wrap:follow',
          '--bind=enter:toggle',
          "--bind=tab:execute(#{view_cmd})",
          '--bind=ctrl-a:select-all',
          '--bind=ctrl-d:deselect-all',
          '--bind=ctrl-s:execute-silent(echo {+} > sumo-selected.txt)+abort',
          '--bind=ctrl-y:execute-silent(echo {+} | pbcopy || echo {+} | xclip -selection clipboard 2>/dev/null)+abort',
          '--bind=ctrl-e:execute-silent(echo {+} > sumo-export.jsonl)+abort',
          '--bind=ctrl-/:toggle-preview',
          "--bind=ctrl-r:reload(cat #{input_path})",
          '--bind=ctrl-q:abort',
          '--height=100%'
        ]
      end

      def build_view_command(preview_path)
        # FZF {n} is 0-indexed! Add 1 to get sed line number (1-indexed)
        'LINE=$(({n} + 1)); ' \
          "sed -n \"$LINE\"p #{Shellwords.escape(preview_path)} | jq -C . | less -R"
      end

      def build_preview_command(preview_path)
        # FZF {n} is 0-indexed! Add 1 to get JSONL line number (1-indexed)
        escaped_path = Shellwords.escape(preview_path)
        calc = "LINE=$(({n} + 1)); TOTAL=$(wc -l < #{escaped_path}); "
        display = 'echo "Message $LINE of $TOTAL"; echo ""; '
        extract = "sed -n \"$LINE\"p #{escaped_path}"

        calc + display + "#{extract} | jq -C . || #{extract}"
      end

      def build_header_text
        query = @results['query'] || 'N/A'
        count = @messages.size
        sources = @messages.map { |m| m['map']['_sourceCategory'] }.compact.uniq.size

        # Column headers
        columns = "#{pad('TIME', 8)} #{pad('LEVEL', 7)} #{pad('SOURCE', 25)} MESSAGE"
        # Info and keys on second line
        info = "#{count} msgs | #{sources} sources | Query: #{truncate(query, 40)}"
        keys = 'Enter=select Tab=view Ctrl-S=save Ctrl-Y=copy Ctrl-E=export Ctrl-Q=quit'

        "#{columns}\n#{info} | #{keys}"
      end

      def pad(text, width)
        text.ljust(width)
      end

      def handle_selection(selected)
        # Selected contains the actual display lines (no index field)
        # We don't show them since user already saw in FZF
        # The keybindings (Ctrl-S, Ctrl-Y, Ctrl-E) handle the export
        return if selected.empty?

        puts "\n#{'═' * 80}"
        puts '📋 Exited interactive mode'
        puts '═' * 80
        puts "\n💡 Your selected messages were:"
        puts '   • Saved to file (if you pressed Ctrl-S)'
        puts '   • Copied to clipboard (if you pressed Ctrl-Y)'
        puts '   • Exported to JSONL (if you pressed Ctrl-E)'
      end
    end
  end
end
