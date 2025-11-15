# frozen_string_literal: true

module Sumologic
  module Interactive
    class Error < StandardError; end

    class << self
      def launch(results)
        raise Error, fzf_install_message unless fzf_available?

        require_relative 'interactive/fzf_viewer'
        FzfViewer.new(results).run
      end

      private

      def fzf_available?
        system('which fzf > /dev/null 2>&1')
      end

      def fzf_install_message
        <<~MSG

          ╔════════════════════════════════════════════════════════════╗
          ║  Interactive mode requires FZF to be installed             ║
          ╚════════════════════════════════════════════════════════════╝

          📦 Install FZF:

             macOS:    brew install fzf
             Ubuntu:   sudo apt-get install fzf
             Fedora:   sudo dnf install fzf
             Arch:     sudo pacman -S fzf

          🔗 Or visit: https://github.com/junegunn/fzf#installation

          After installing, run your command again with -i flag.
        MSG
      end
    end
  end
end
