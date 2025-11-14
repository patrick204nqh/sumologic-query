# Architecture

This document explains the internal architecture of the Sumo Logic Query Tool and how it works.

## Table of Contents

- [Overview](#overview)
- [Component Structure](#component-structure)
- [Search Workflow](#search-workflow)
- [Metadata Workflow](#metadata-workflow)
- [Design Principles](#design-principles)

## Overview

The tool follows a modular, layered architecture with clear separation of concerns:

- **Configuration Layer**: Manages credentials and settings
- **HTTP Layer**: Handles API authentication and requests
- **Search Layer**: Manages search jobs, polling, and pagination
- **Metadata Layer**: Handles collector and source operations
- **Client Layer**: Provides a unified facade for all operations
- **CLI Layer**: Thor-based command-line interface

## Component Structure

```
lib/sumologic/
├── configuration.rb       # Configuration management
├── client.rb             # Main client facade
├── cli.rb                # Thor-based CLI
├── http/
│   ├── authenticator.rb  # API authentication
│   └── client.rb         # HTTP request handling
├── search/
│   ├── job.rb            # Search job creation
│   ├── poller.rb         # Job status polling
│   └── paginator.rb      # Result pagination
└── metadata/
    ├── collector.rb      # Collector operations
    └── source.rb         # Source operations
```

### Configuration Layer

**File**: `lib/sumologic/configuration.rb`

Centralizes configuration management:

```ruby
config = Sumologic::Configuration.new(
  access_id: ENV['SUMO_ACCESS_ID'],
  access_key: ENV['SUMO_ACCESS_KEY'],
  deployment: ENV.fetch('SUMO_DEPLOYMENT', 'us2'),
  timeout: 300
)
```

**Responsibilities**:
- Load and validate credentials
- Construct API endpoint URLs
- Manage timeout settings
- Provide deployment-specific configurations

### HTTP Layer

**Files**: `lib/sumologic/http/`

#### Authenticator (`authenticator.rb`)

Handles API authentication:
- Creates Basic Auth headers
- Encodes credentials
- Provides authorization tokens

#### HTTP Client (`client.rb`)

Manages all HTTP communication:
- Makes GET, POST, DELETE requests
- Handles response parsing
- Manages errors and retries
- Provides consistent error messages

**Example**:
```ruby
http = Sumologic::Http::Client.new(config: config)
response = http.request(
  method: :get,
  path: '/collectors'
)
```

### Search Layer

**Files**: `lib/sumologic/search/`

#### Job (`job.rb`)

Creates and manages search jobs:
- POST `/api/v1/search/jobs` to create job
- Returns job ID for polling
- Validates query parameters

#### Poller (`poller.rb`)

Polls job status until completion:
- GET `/api/v1/search/jobs/:id` every 20 seconds
- Monitors state: `NOT STARTED` → `GATHERING RESULTS` → `DONE GATHERING RESULTS`
- Tracks progress: message count, record count
- Handles timeouts (default: 5 minutes)

**State Machine**:
```
NOT STARTED
    ↓
GATHERING RESULTS (polling every 20s)
    ↓
DONE GATHERING RESULTS
    ↓
Results ready
```

#### Paginator (`paginator.rb`)

Fetches results with automatic pagination:
- GET `/api/v1/search/jobs/:id/messages`
- Fetches 10,000 messages per request
- Automatically handles pagination
- Applies optional limit to results

**Pagination Flow**:
```
Request 1: offset=0, limit=10000  → 10,000 messages
Request 2: offset=10000, limit=10000 → 10,000 messages
Request 3: offset=20000, limit=10000 → 5,432 messages
Total: 25,432 messages
```

### Metadata Layer

**Files**: `lib/sumologic/metadata/`

#### Collector (`collector.rb`)

Lists collectors:
- GET `/api/v1/collectors`
- Returns all collectors with status
- Filters for alive/offline status

#### Source (`source.rb`)

Lists sources:
- GET `/api/v1/collectors/:id/sources` for specific collector
- `list_all` fetches from all active collectors
- Includes collector context with sources

### Client Layer

**File**: `lib/sumologic/client.rb`

Provides a unified facade:

```ruby
client = Sumologic::Client.new(
  access_id: '...',
  access_key: '...'
)

# Search logs
results = client.search(query: 'error', ...)

# List collectors
collectors = client.list_collectors

# List sources
sources = client.list_all_sources
```

**Responsibilities**:
- Initialize all sub-components
- Coordinate between layers
- Provide simple, high-level API
- Handle cross-cutting concerns

### CLI Layer

**File**: `lib/sumologic/cli.rb`

Thor-based command-line interface:

```ruby
class CLI < Thor
  desc "search", "Search Sumo Logic logs"
  def search
    # ...
  end

  desc "collectors", "List collectors"
  def collectors
    # ...
  end

  desc "sources", "List sources"
  def sources
    # ...
  end
end
```

**Responsibilities**:
- Parse command-line arguments
- Validate required options
- Display progress and status
- Format output (JSON to stdout/file)

## Search Workflow

### Step-by-Step Process

1. **User initiates search**:
   ```bash
   sumo-query search --query 'error' --from '2025-11-13T14:00:00' --to '2025-11-13T15:00:00'
   ```

2. **CLI validates and parses options**:
   - Check required options (query, from, to)
   - Load credentials from environment
   - Create configuration object

3. **Client creates search job**:
   ```
   POST /api/v1/search/jobs
   Body: {
     query: "error",
     from: "2025-11-13T14:00:00",
     to: "2025-11-13T15:00:00",
     timeZone: "UTC"
   }
   Response: { id: "ABC123..." }
   ```

4. **Poller monitors job status**:
   ```
   GET /api/v1/search/jobs/ABC123

   Poll 1 (t=0s):   state=NOT STARTED, messageCount=0
   Poll 2 (t=20s):  state=GATHERING RESULTS, messageCount=1,234
   Poll 3 (t=40s):  state=GATHERING RESULTS, messageCount=15,678
   Poll 4 (t=60s):  state=DONE GATHERING RESULTS, messageCount=25,432
   ```

5. **Paginator fetches results**:
   ```
   GET /api/v1/search/jobs/ABC123/messages?offset=0&limit=10000
   GET /api/v1/search/jobs/ABC123/messages?offset=10000&limit=10000
   GET /api/v1/search/jobs/ABC123/messages?offset=20000&limit=10000
   ```

6. **Client cleans up**:
   ```
   DELETE /api/v1/search/jobs/ABC123
   ```

7. **CLI outputs results**:
   - Format as JSON
   - Write to stdout or file
   - Display summary statistics

### Timing Example

For a typical query:

```
00:00 - Create job (POST /search/jobs)
00:01 - First poll (GET /search/jobs/:id)
00:21 - Second poll
00:41 - Third poll
01:01 - Fourth poll → DONE
01:02 - Fetch page 1 (GET /messages?offset=0)
01:03 - Fetch page 2 (GET /messages?offset=10000)
01:04 - Fetch page 3 (GET /messages?offset=20000)
01:05 - Cleanup (DELETE /search/jobs/:id)
01:06 - Output results
```

**Total time**: ~66 seconds

## Metadata Workflow

### Listing Collectors

```
1. User runs: sumo-query collectors
2. CLI creates client
3. Client calls: GET /api/v1/collectors
4. Response: [{ id: 1, name: "prod-collector", alive: true }, ...]
5. CLI outputs JSON
```

### Listing All Sources

```
1. User runs: sumo-query sources
2. CLI creates client
3. Client lists collectors: GET /api/v1/collectors
4. For each active collector:
   - GET /api/v1/collectors/:id/sources
   - Collect sources with collector context
5. CLI outputs combined JSON
```

## Design Principles

### 1. Separation of Concerns

Each module has a single, well-defined responsibility:
- HTTP layer doesn't know about search logic
- Search layer doesn't handle HTTP details
- CLI layer doesn't perform business logic

### 2. Testability

Components are loosely coupled and dependency-injected:

```ruby
# Easy to test with mocks
job = Sumologic::Search::Job.new(http_client: mock_http)
poller = Sumologic::Search::Poller.new(http_client: mock_http)
```

### 3. Error Handling

Errors are caught and re-raised with context:

```ruby
rescue StandardError => e
  raise Error, "Failed to list collectors: #{e.message}"
end
```

### 4. Configuration

All configuration is centralized and validated:

```ruby
# Single source of truth
config = Configuration.new(...)
config.api_url  # https://api.us2.sumologic.com/api/v1
```

### 5. Minimal Dependencies

- Uses only Ruby stdlib for core functionality
- Thor for CLI (optional, gracefully degraded)
- No heavy frameworks or unnecessary gems

### 6. Read-Only Operations

All operations are read-only:
- No POST/PUT/PATCH for data modification
- Only search and metadata retrieval
- Safe for production environments

## Performance Considerations

### Polling Interval

- 20 seconds between polls
- Balances responsiveness vs. API load
- Follows Sumo Logic best practices

### Pagination

- 10,000 messages per request
- Maximum allowed by API
- Minimizes number of requests

### Timeouts

- Default: 5 minutes (300 seconds)
- Configurable via Configuration
- Prevents indefinite waits

### Memory

- Streams results (doesn't load all in memory)
- Processes pagination incrementally
- Suitable for large result sets

## API Endpoints Used

### Search API

- `POST /api/v1/search/jobs` - Create search job
- `GET /api/v1/search/jobs/:id` - Get job status
- `GET /api/v1/search/jobs/:id/messages` - Fetch results
- `DELETE /api/v1/search/jobs/:id` - Cleanup job

### Metadata API

- `GET /api/v1/collectors` - List collectors
- `GET /api/v1/collectors/:id/sources` - List sources for collector

## See Also

- [Examples](examples.md) - Query patterns and use cases
- [API Reference](api-reference.md) - Ruby library documentation
- [Troubleshooting](troubleshooting.md) - Common issues
