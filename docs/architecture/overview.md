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
│   ├── client.rb
│   └── connection_pool.rb  # Thread-safe connection pool
├── search/               # Search operations
│   ├── job.rb
│   ├── poller.rb
│   ├── paginator.rb
│   └── stream.rb         # Streaming interface
└── metadata/             # Metadata operations
    ├── collector.rb
    ├── source.rb
    └── parallel_fetcher.rb  # Parallel fetching utility
```

## Layers

### Configuration
Manages credentials and settings. Constructs API URLs based on deployment.

### HTTP
- **Client**: Handles authentication and HTTP requests with consistent error handling
- **Connection Pool**: Thread-safe pool of persistent HTTP connections (max 10)
- **Authenticator**: Generates Basic Auth headers

### Search
- **Job**: Creates and manages search job lifecycle
- **Poller**: Monitors job status with immediate polling and exponential backoff
- **Paginator**: Fetches results with automatic pagination (sequential or parallel)
- **Stream**: Enumerator-based streaming for memory-efficient processing

### Metadata
- **Collector**: Lists collectors
- **Source**: Lists sources from collectors
- **Parallel Fetcher**: Thread-safe utility for concurrent operations (max 10 workers)

### Client
Unified facade that coordinates all operations.

### CLI
Thor-based command-line interface with three commands:
- `search` - Query logs
- `collectors` - List collectors
- `sources` - List sources

## How Search Works

1. **Create job**: POST query to `/api/v1/search/jobs`
2. **Poll status**: GET job status immediately, then with exponential backoff (5s → 7.5s → 11.25s → 20s max)
3. **Fetch results**: GET messages with automatic pagination
   - Sequential: One page at a time (default for small queries)
   - Parallel: 5 pages concurrently (for queries with 20K+ messages)
4. **Cleanup**: DELETE job

## How Metadata Works

1. **List collectors**: GET `/api/v1/collectors`
2. **List sources**: GET `/api/v1/collectors/:id/sources` for each collector
   - Parallel fetching: 10 collectors concurrently for better performance

## Key Concepts

**Connection Pooling**: Persistent HTTP connections (up to 10) with keep-alive for reduced latency.

**Thread Safety**: Mutex-protected connection pool and parallel operations.

**Polling**: Immediate status check, then exponential backoff (5s → 20s max).

**Pagination**:
- Sequential: One page at a time (thread-safe, lower overhead)
- Parallel: 5 pages concurrently (enabled by default for 20K+ messages)

**Streaming**: Optional Enumerator interface for memory-efficient processing.

**Deployment-aware**: API URLs change based on deployment region (us1, us2, eu, etc.).

**Error types**:
- `AuthenticationError` - Invalid credentials
- `TimeoutError` - Search took too long
- `Error` - General errors

## Performance Features

For details on performance optimizations, see [Architecture Decision Records](decisions/).

Key performance characteristics:
- Connection pooling: 20-30% faster API calls
- Parallel source fetching: 85% faster (100 collectors)
- Immediate polling: 5 seconds saved per query
- Parallel pagination: 50-70% faster (large queries)
- Streaming: 95% memory reduction (large result sets)

For implementation details, see the source code in `lib/sumologic/`.

For query examples, see [examples/queries.md](../../examples/queries.md).
