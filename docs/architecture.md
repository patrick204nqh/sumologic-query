# Architecture

Understanding how the tool is organized and how it works.

## Design Philosophy

- **Modular**: Separate concerns (HTTP, Search, Metadata, CLI)
- **Simple**: Minimal dependencies, straightforward code
- **Read-only**: No write operations to Sumo Logic
- **Testable**: Loose coupling, dependency injection

## Component Structure

```
lib/sumologic/
├── configuration.rb       # Config management
├── client.rb             # Main facade
├── cli.rb                # CLI interface
├── http/                 # HTTP layer
│   ├── authenticator.rb
│   └── client.rb
├── search/               # Search operations
│   ├── job.rb
│   ├── poller.rb
│   └── paginator.rb
└── metadata/             # Metadata operations
    ├── collector.rb
    └── source.rb
```

## Layers

### Configuration
Manages credentials and settings. Constructs API URLs based on deployment.

### HTTP
Handles authentication and HTTP requests. Provides consistent error handling.

### Search
- **Job**: Creates search jobs
- **Poller**: Monitors job status until complete (polls every 20s)
- **Paginator**: Fetches results with automatic pagination

### Metadata
- **Collector**: Lists collectors
- **Source**: Lists sources from collectors

### Client
Unified facade that coordinates all operations.

### CLI
Thor-based command-line interface with three commands:
- `search` - Query logs
- `collectors` - List collectors
- `sources` - List sources

## How Search Works

1. **Create job**: POST query to `/api/v1/search/jobs`
2. **Poll status**: GET job status every 20 seconds until complete
3. **Fetch results**: GET messages with automatic pagination (10K per request)
4. **Cleanup**: DELETE job

## How Metadata Works

1. **List collectors**: GET `/api/v1/collectors`
2. **List sources**: GET `/api/v1/collectors/:id/sources` for each collector

## Key Concepts

**Polling**: Search jobs are asynchronous. The tool polls status until the job completes.

**Pagination**: Results are fetched in chunks (10K messages per request) to handle large datasets.

**Deployment-aware**: API URLs change based on deployment region (us1, us2, eu, etc.).

**Error types**:
- `AuthenticationError` - Invalid credentials
- `TimeoutError` - Search took too long
- `Error` - General errors

For implementation details, see the source code in `lib/sumologic/`.

For query examples, see [examples/queries.md](../examples/queries.md).
