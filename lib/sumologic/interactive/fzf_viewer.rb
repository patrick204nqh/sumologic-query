# frozen_string_literal: true

require 'json'
require 'tempfile'
require 'time'
require 'open3'
require_relative 'fzf_viewer/config'
require_relative 'fzf_viewer/formatter'
require_relative 'fzf_viewer/searchable_builder'
require_relative 'fzf_viewer/fzf_config'
require_relative 'fzf_viewer/header_builder'

module Sumologic
  module Interactive
    class FzfViewer
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

      # ============================================================
      # Data Preparation
      # ============================================================

      def prepare_data(input_file, preview_file)
        write_input_file(input_file)
        write_preview_file(preview_file)
      end

      def write_input_file(input_file)
        File.open(input_file, 'w') do |f|
          @messages.each { |msg| f.puts format_line(msg) }
        end
      end

      def write_preview_file(preview_file)
        File.open(preview_file, 'w') do |f|
          @messages.each { |msg| f.puts JSON.generate(msg['map']) }
        end
      end

      # ============================================================
      # Line Formatting
      # ============================================================

      def format_line(msg)
        map = msg['map']
        display = build_display_line(map)
        searchable = SearchableBuilder.build_searchable_content(map)

        "#{display}#{' ' * Config::SEARCHABLE_PADDING}#{searchable}"
      end

      def build_display_line(map)
        time = Formatter.format_time(map['_messagetime'])
        level = Formatter.format_level(map['level'] || map['severity'] || 'INFO')
        source = Formatter.truncate(map['_source'] || map['_sourcecategory'] || '-', Config::SOURCE_WIDTH)
        message = Formatter.truncate(Formatter.sanitize(map['_raw'] || map['message'] || ''), Config::MESSAGE_PREVIEW_LENGTH)

        "#{time} #{level} #{source.ljust(Config::SOURCE_WIDTH)} #{message}"
      end

      # ============================================================
      # FZF Execution
      # ============================================================

      def execute_fzf(input_path, preview_path)
        header_text = HeaderBuilder.build_header_text(@results, @messages)
        fzf_args = FzfConfig.build_fzf_args(input_path, preview_path, header_text)

        result = IO.popen(fzf_args, 'r+') do |io|
          File.readlines(input_path).each { |line| io.puts line }
          io.close_write
          io.read
        end

        result.strip
      end

      # ============================================================
      # Selection Handling
      # ============================================================

      def handle_selection(selected)
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
