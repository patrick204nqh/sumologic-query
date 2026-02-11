# Changelog

All notable changes to this project will be documented in this file.

This project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and release notes are automatically generated from commit messages.
## [1.4.2](https://github.com/patrick204nqh/sumologic-query/compare/v1.4.1...v1.4.2) (2026-02-11)

### 🎉 New Features

- add source discovery guidance to skills
- add filtering options to list-sources
- add keyword and limit filters to discover-source-metadata
- add -q/--query and -l/--limit flags to list-collectors

### 🐛 Bug Fixes

- support compound relative time expressions like -1h30m



## [1.4.1](https://github.com/patrick204nqh/sumologic-query/compare/v1.4.0...v1.4.1) (2026-02-11)

### 🎉 New Features

- add "Open in Sumo Logic" URL to search output
- add command recipe and CLI command specs

### 🐛 Bug Fixes

- update source_code_uri metadata to use homepage

### 🔧 Refactoring

- resolve ADR-006, fix README links, extract command helpers

### 📚 Documentation

- consolidate query examples and document v1/v2 API split



## [1.4.0](https://github.com/patrick204nqh/sumologic-query/compare/v1.3.5...v1.4.0) (2026-02-11)

### 🎉 New Features

- add comprehensive skills documentation for Sumo Logic CLI commands
- add export-content command with async job handling
- add get-content command for path-based content lookup
- add get-lookup and list-apps commands
- add list-health-events and list-fields commands
- migrate monitors to search API with status/query filters
- add support for retrieving monitors and dashboards in the CLI, refactor monitor collection logic for improved readability
- Enhance Sumo Logic CLI with monitors, folders, and dashboards commands
- implement aggregation queries and enhance error handling for rate limits

### 🐛 Bug Fixes

- migrate dashboards from v1 to v2 API

### 🔧 Refactoring

- clean design for AI agent readiness (v1.4.0)

### 📚 Documentation

- update naming conventions to match actual codebase
- reorganize into SDLC structure
- clarify discover-sources as search-based technique
- revise architecture overview with enhanced clarity on design philosophy, component structure, and key features



## [1.3.5](https://github.com/patrick204nqh/sumologic-query/compare/v1.3.4...v1.3.5) (2025-11-19)

### 🎉 New Features

- add discover-sources command for dynamic source discovery from logs
- implement rate limiting configuration and enhance documentation for querying options

### 🔧 Refactoring

- improve source discovery logic and enhance debugging output

### 📚 Documentation

- update tldr.md with enhanced search options and new commands for querying logs



## [1.3.4](https://github.com/patrick204nqh/sumologic-query/compare/v1.3.3...v1.3.4) (2025-11-19)

### 🎉 New Features

- add time parsing utility and enhance CLI time options for flexible querying
- enhance debug logging to include request headers for better traceability

### 🐛 Bug Fixes

- freeze regex for relative time parsing and improve error message formatting

### 📚 Documentation

- update README and examples to enhance time format usage and add new time format examples



## [1.3.3](https://github.com/patrick204nqh/sumologic-query/compare/v1.3.2...v1.3.3) (2025-11-17)

### 🎉 New Features

- implement modular HTTP client components for improved organization and functionality
- refactor CLI structure to modular commands and remove deprecated modules
- update CHANGELOG entry creation to include changelog content directly
- bump version to 1.3.3
- add ADR for SSL certificate verification to address connection issues with Sumo Logic API
- refactor CLI structure into modular components for improved organization and maintainability
- implement debug logging for HTTP requests and responses
- enhance release notes generation and update CHANGELOG format for better clarity




## [1.3.2](https://github.com/patrick204nqh/sumologic-query/compare/v1.3.1...v1.3.2) (2025-11-16)

### 🎉 New Features

- Refactor FzfViewer with modular configuration, formatting, and header building for better maintainability
- Add modular file structure with separate concerns (Config, Formatter, SearchableBuilder, FzfConfig, HeaderBuilder)
- Implement module_function for better encapsulation in all FzfViewer modules
- Add RubyGems download badge to README

### 🐛 Bug Fixes

- Update source field reference in FzfViewer for consistency (use lowercase `_source` field)
- Fix RuboCop offenses across all FzfViewer modules

### 🔧 Refactoring

- Extract searchable builder methods to reduce complexity
- Separate FzfViewer into 6 focused modules (~50-100 lines each)
- Use constants for display configuration (widths, colors, padding)
- Improve code organization with clear section headers

### 🧹 Maintenance

- Update release notes generation and changelog management in CI pipeline

## [1.3.1](https://github.com/patrick204nqh/sumologic-query/compare/v1.3.0...v1.3.1) (2025-11-15)

### 🧹 Maintenance

- Automated version bump and release preparation

## [1.3.0](https://github.com/patrick204nqh/sumologic-query/compare/v1.2.1...v1.3.0) (2025-11-15)

### 📚 Documentation

- Establish commit message convention using Conventional Commits
- Update CONTRIBUTING.md for clarity and best practices

### 🧹 Maintenance

- Remove path restriction for version file in release workflow
- Improve CI/CD pipeline configuration

## [1.2.1](https://github.com/patrick204nqh/sumologic-query/compare/v1.2.0...v1.2.1) (2025-11-14)

### 🎉 New Features

- Add interactive mode with FZF for enhanced log exploration
- Support real-time log browsing and filtering
- Add keyboard shortcuts for common operations

### 📚 Documentation

- Update CLI and documentation to support new interactive feature
- Add usage examples for interactive mode

## [1.2.0](https://github.com/patrick204nqh/sumologic-query/compare/v1.1.2...v1.2.0) (2025-11-14)

### 🎉 New Features

- Add ADR 004 for enhanced progress tracking and user experience
- Implement real-time visibility with callbacks in CLI and fetcher classes
- Add comprehensive progress indicators for long-running operations

### 🔧 Refactoring

- Implement reusable Worker utility for parallel execution
- Refactor metadata and search fetching classes to utilize Worker
- Remove deprecated ParallelFetcher and Paginator
- Simplify pagination logic
- Remove streaming APIs for better maintainability
- Update configuration defaults for optimal performance

### 📚 Documentation

- Reorganize architecture documentation files
- Add architectural overview and decision records

## [1.1.2](https://github.com/patrick204nqh/sumologic-query/compare/v1.1.1...v1.1.2) (2025-11-14)

### 🐛 Bug Fixes

- Fix command syntax in tldr.md for listing collectors and sources

### 🎉 New Features

- Add version command to CLI

### 📚 Documentation

- Add quick reference documentation (tldr.md)
- Refactor documentation structure
- Remove examples.md and consolidate content
- Streamline troubleshooting.md
- Consolidate queries.md with improved examples

## [1.1.1](https://github.com/patrick204nqh/sumologic-query/compare/v1.1.0...v1.1.1) (2025-11-14)

### 🔧 Refactoring

- Refactor search logging in CLI and Poller classes for improved readability
- Consolidate attribute accessors in Configuration class
- Improve CLI options structure

## [1.1.0](https://github.com/patrick204nqh/sumologic-query/compare/v1.0.1...v1.1.0) (2025-11-13)

### 🎉 New Features

- Add CLI support with Thor framework
- Refactor Sumo Logic client for better usability

### 🔧 Refactoring

- Refine polling logic in Sumo Logic client
- Improve overall code structure and organization

### 🧹 Maintenance

- Refactor CI and release workflows
- Streamline version checking and build process
- Improve release tagging automation

## [1.0.1](https://github.com/patrick204nqh/sumologic-query/compare/v1.0.0...v1.0.1) (2025-11-13)

### 🎉 New Features

- Add CODEOWNERS file for repository management

### 🧹 Maintenance

- Refactor release workflow to generate release notes using GitHub API
- Update CHANGELOG.md format for better clarity
- Add changelog extraction for automated versioning

## [1.0.0](https://github.com/patrick204nqh/sumologic-query/releases/tag/v1.0.0) (2025-11-13)

### 🎉 Initial Release

- Initial release of Sumo Logic Query Tool
- Core search functionality
- Metadata querying (collectors, sources)
- Basic CLI interface
- HTTP client with authentication
- Automated pagination
- Search job polling
- JSON output support
