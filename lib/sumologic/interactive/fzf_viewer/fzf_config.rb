# frozen_string_literal: true

require 'shellwords'

module Sumologic
  module Interactive
    class FzfViewer
      module FzfConfig
        module_function

        def build_fzf_args(input_path, preview_path, header_text)
          [
            'fzf',
            *search_options,
            *display_options(preview_path, header_text),
            *keybinding_options(input_path, preview_path)
          ]
        end

        def search_options
          [
            '--ansi',
            '--multi',
            '--exact',       # Exact substring matching
            '-i',            # Case-insensitive
            '--no-hscroll'   # Prevent horizontal scrolling
          ]
        end

        def display_options(preview_path, header_text)
          [
            "--header=#{header_text}",
            "--preview=#{build_preview_command(preview_path)}",
            '--preview-window=right:60%:wrap:follow',
            '--height=100%'
          ]
        end

        def keybinding_options(input_path, preview_path)
          [
            '--bind=enter:toggle',
            "--bind=tab:execute(#{build_view_command(preview_path)})",
            '--bind=ctrl-a:select-all',
            '--bind=ctrl-d:deselect-all',
            '--bind=ctrl-s:execute-silent(echo {+} > sumo-selected.txt)+abort',
            '--bind=ctrl-y:execute-silent(echo {+} | pbcopy || ' \
            'echo {+} | xclip -selection clipboard 2>/dev/null)+abort',
            '--bind=ctrl-e:execute-silent(echo {+} > sumo-export.jsonl)+abort',
            '--bind=ctrl-/:toggle-preview',
            "--bind=ctrl-r:reload(cat #{input_path})",
            '--bind=ctrl-t:toggle-search',
            '--bind=ctrl-q:abort'
          ]
        end

        def build_view_command(preview_path)
          # FZF {n} is 0-indexed, sed is 1-indexed
          'LINE=$(({n} + 1)); ' \
            "sed -n \"$LINE\"p #{Shellwords.escape(preview_path)} | jq -C . | less -R"
        end

        def build_preview_command(preview_path)
          escaped_path = Shellwords.escape(preview_path)

          calc = "LINE=$(({n} + 1)); TOTAL=$(wc -l < #{escaped_path}); "
          display = 'echo "Message $LINE of $TOTAL"; echo ""; '
          extract = "sed -n \"$LINE\"p #{escaped_path}"

          "#{calc}#{display}#{extract} | jq -C . || #{extract}"
        end
      end
    end
  end
end
