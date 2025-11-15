# Changelog

All notable changes to this project will be documented in this file.

This project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this changelog is automatically generated using [Conventional Commits](https://conventionalcommits.org/).

## [1.1.0](https://github.com/patrick204nqh/sumologic-query/releases/tag/v1.1.0) - Latest

### Features
- Add interactive mode with FZF for enhanced log exploration
- Add real-time progress tracking with callbacks

### Documentation
- Update CLI and documentation to support new features
- Add ADR 004 for enhanced progress tracking and user experience

### Refactor
- Implement reusable Worker utility for parallel execution
- Refactor metadata and search fetching classes to utilize Worker
- Remove deprecated ParallelFetcher and Paginator
- Simplify pagination and remove streaming APIs

## [1.0.0](https://github.com/patrick204nqh/sumologic-query/releases/tag/v1.0.0) - Initial Release

### Features
- Initial release of sumologic-query CLI
- Search Job API integration
- Automatic pagination and polling
- Read-only access to Sumo Logic logs
