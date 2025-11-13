# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2025-11-13

### Added
- Initial release of sumologic-query CLI tool
- Core `Sumologic::Client` class for Search Job API
- Command-line interface with query, time range, and output options
- Automatic job polling with 20-second intervals
- Automatic pagination for large result sets (10K messages per request)
- Support for multiple Sumo Logic deployments (us1, us2, eu, au)
- Environment variable configuration (SUMO_ACCESS_ID, SUMO_ACCESS_KEY, SUMO_DEPLOYMENT)
- Debug mode for troubleshooting (SUMO_DEBUG)
- JSON output format with metadata
- Zero external dependencies (stdlib only)
- Comprehensive error handling and user-friendly messages
- MIT license
- Complete documentation and examples

### Features
- Query historical logs via Search Job API
- Time range filtering (ISO 8601 format)
- Message limiting
- Timezone support
- File or stdout output
- 5-minute default timeout
- Graceful cleanup of search jobs

[1.0.0]: https://github.com/patrick204nqh/sumologic-query/releases/tag/v1.0.0
