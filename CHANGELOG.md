# Changelog

All notable changes to this project will be documented in this file.

This project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and release notes are automatically generated from commit messages.

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
