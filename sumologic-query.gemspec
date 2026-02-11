# frozen_string_literal: true

require_relative 'lib/sumologic/version'

Gem::Specification.new do |spec|
  spec.name = 'sumologic-query'
  spec.version = Sumologic::VERSION
  spec.authors = ['patrick204nqh']
  spec.email = ['patrick204nqh@gmail.com']

  spec.summary = 'A lightweight Ruby CLI for querying Sumo Logic logs quickly'
  spec.description = <<~DESC
    Simple, fast, read-only access to Sumo Logic logs via the Search Job API.
    No complex features, just quick log queries with automatic pagination and polling.
    Perfect for DevOps, incident investigation, and log analysis workflows.
  DESC
  spec.homepage = 'https://github.com/patrick204nqh/sumologic-query'
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 2.7.0'

  spec.metadata['source_code_uri'] = spec.homepage
  spec.metadata['bug_tracker_uri'] = 'https://github.com/patrick204nqh/sumologic-query/issues'
  spec.metadata['changelog_uri'] = 'https://github.com/patrick204nqh/sumologic-query/blob/main/CHANGELOG.md'
  spec.metadata['rubygems_mfa_required'] = 'true'

  # Specify which files should be added to the gem when it is released.
  spec.files = Dir.glob(%w[
                          lib/**/*.rb
                          bin/*
                          LICENSE
                          README.md
                          CHANGELOG.md
                        ])
  spec.bindir = 'bin'
  spec.executables = ['sumo-query']
  spec.require_paths = ['lib']

  # Runtime dependencies
  # base64 is required for Ruby 3.4+ but was part of stdlib before
  spec.add_dependency 'base64', '~> 0.1'
  # thor for CLI command routing and organization
  spec.add_dependency 'thor', '~> 1.3'

  # Development dependencies
  spec.add_development_dependency 'rake', '~> 13.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'rubocop', '~> 1.21'
end
