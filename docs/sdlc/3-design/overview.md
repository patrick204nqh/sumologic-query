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
├── cli/commands/         # Command handlers (5 commands)
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
sumo-query discover-sources --filter '_sourceCategory=*ecs*'
```

List infrastructure:

```bash
sumo-query list-collectors
sumo-query list-sources
```

## Related Documentation

- [Architecture Decision Records](decisions/) - Detailed design decisions
- [ADR 002](decisions/002-radical-simplification.md) - Simplification philosophy
- [ADR 005](decisions/005-interactive-mode-with-fzf.md) - Interactive mode design
- [ADR 007](decisions/007-dynamic-source-discovery.md) - Source discovery
- [Query Examples](../../examples/queries.md) - Query patterns
- [Rate Limiting](../rate-limiting.md) - Performance tuning
