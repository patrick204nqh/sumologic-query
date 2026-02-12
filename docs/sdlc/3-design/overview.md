# Architecture Overview

> Modular Ruby CLI for querying Sumo Logic logs and metadata.
> Read-only, simple, testable design with interactive exploration support.
> More information: <https://github.com/patrick204nqh/sumologic-query>.

## Component Structure

```
lib/sumologic/
├── configuration.rb       # Config management
├── client.rb             # Main facade
├── cli.rb                # CLI interface
├── http/                 # HTTP layer (7 components)
├── search/               # Search operations (4 components)
├── metadata/             # Metadata operations (6 components)
├── interactive/          # FZF-based browser (6 components)
├── cli/commands/         # Command handlers (16 commands)
└── utils/                # Utilities (2 components)
```

## How It Works

### Search Flow

```
Query → Create Job → Poll (2s intervals) → Fetch Messages → Output JSON
```

With interactive mode:

```
Query → Create Job → Poll → Fetch Messages → Launch FZF → Explore/Save
```

### Dynamic Source Discovery

```
Build Query → Create Job → Poll → Fetch Records → Format Sources
```

Uses aggregation: `* | count by _sourceName, _sourceCategory | sort by _count desc`

### Static Metadata

```
GET /collectors → Parallel Fetch (10 workers) → GET /collectors/:id/sources
```

## Key Features

- **Connection pooling**: 10 persistent connections, 20-30% faster
- **Aggressive polling**: 2s initial interval, exponential backoff to 15s
- **Parallel fetching**: 10 concurrent workers for metadata operations
- **Interactive mode**: JSONL format, handles 100k+ messages efficiently
- **Flexible time parsing**: Relative (`-1h`), ISO 8601, Unix timestamps, timezones
- **Deployment aware**: Auto-configures API URLs for us1, us2, eu, au regions

## API Versions (v1 vs v2)

The Sumo Logic API has two base URLs. The client initializes both as `@http` (v1) and `@http_v2` (v2):

| API version | Base path | Resources |
|-------------|-----------|-----------|
| **v1** (`@http`) | `/api/v1` | Search, Collectors, Sources, Monitors, Health Events, Fields, Lookup Tables, Apps |
| **v2** (`@http_v2`) | `/api/v2` | Dashboards, Folders, Content (path lookup + export) |

When adding a new metadata class, check which base URL the Sumo Logic endpoint uses and pass the corresponding HTTP client:

```ruby
# v1 example
@app = Metadata::App.new(http_client: @http)

# v2 example
@dashboard = Metadata::Dashboard.new(http_client: @http_v2)
```

See `lib/sumologic/client.rb` for the full initialization.

## Design Decisions

Per ADR 002, removed complexity:
- No parallel pagination (sequential only)
- No streaming API (use limit parameter)
- No configuration overload (works out-of-box)

## Examples

Search logs:

```bash
sumo-query search -q 'error' -f '-1h' -t 'now'
```

Interactive exploration:

```bash
sumo-query search -q 'error' -f '-1h' -t 'now' -i
```

Discover dynamic sources:

```bash
sumo-query discover-source-metadata --filter '_sourceCategory=*ecs*'
```

List infrastructure:

```bash
sumo-query list-collectors
sumo-query list-sources
```

## Related Documentation

- [Architecture Decision Records](decisions/) - Detailed design decisions
- [ADR 002](decisions/002-radical-simplification.md) - Simplification philosophy
- [ADR 005](decisions/005-interactive-fzf.md) - Interactive mode design
- [ADR 007](decisions/007-source-metadata-discovery.md) - Source discovery
- [Query Examples](../../../examples/queries.md) - Query patterns
- [Rate Limiting](../4-develop/rate-limiting.md) - Performance tuning
