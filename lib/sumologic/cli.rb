# frozen_string_literal: true

require 'thor'
require_relative 'cli/base'
require_relative 'cli/formatters'
require_relative 'cli/output_handler'
require_relative 'cli/commands/search'
require_relative 'cli/commands/metadata'

module Sumologic
  # Thor-based CLI for Sumo Logic query tool
  # Orchestrates commands through modular components
  class CLI < Thor
    include Base
    include Formatters
    include OutputHandler
    include Commands::Search
    include Commands::Metadata

    desc 'version', 'Show version information'
    def version
      puts "sumo-query version #{Sumologic::VERSION}"
    end
    map %w[-v --version] => :version

    default_task :search
  end
end
