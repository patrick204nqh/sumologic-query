# Sumo Logic Query Tool

> A lightweight Ruby CLI for querying Sumo Logic logs and metadata. Simple, fast, read-only access to your logs.

[![Gem Version](https://badge.fury.io/rb/sumologic-query.svg)](https://badge.fury.io/rb/sumologic-query)
[![Downloads](https://img.shields.io/gem/dt/sumologic-query.svg)](https://rubygems.org/gems/sumologic-query)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## Features

- **Simple time parsing** - Use `-1h`, `-30m`, `now` instead of timestamps
- **Dynamic source discovery** - Find CloudWatch/ECS/Lambda sources from logs
- **Interactive mode** - Explore logs with FZF fuzzy search
- **Timezone support** - US, Australian, and IANA formats
- **Fast & efficient** - Smart polling and pagination
- **Read-only** - Safe log access with no write operations

## Installation

```bash
# Via RubyGems
gem install sumologic-query

# Via Homebrew
brew tap patrick204nqh/tap
brew install sumologic-query
```

## Quick Start

### 1. Set Credentials

```bash
export SUMO_ACCESS_ID="your_access_id"
export SUMO_ACCESS_KEY="your_access_key"
export SUMO_DEPLOYMENT="us2"  # Optional: us1, us2 (default), eu, au
```

Get credentials: Sumo Logic → **Administration → Security → Access Keys**

### 2. Run Queries

```bash
# Search logs
sumo-query search -q 'error' -f '-1h' -t 'now' --limit 100

# Discover dynamic sources (CloudWatch/ECS/Lambda)
sumo-query discover-sources

# List collectors and sources
sumo-query collectors
sumo-query sources
```

## Commands

### 1. Search Logs

```bash
sumo-query search -q "YOUR_QUERY" -f "START" -t "END" [OPTIONS]
```

**Options:**
- `-q, --query` - Query string (required)
- `-f, --from` - Start time (required, e.g., `-1h`, `2025-11-19T14:00:00`)
- `-t, --to` - End time (required, e.g., `now`)
- `-z, --time-zone` - Timezone (default: UTC)
- `-l, --limit` - Max messages to return
- `-o, --output` - Save to file
- `-i, --interactive` - Launch FZF browser
- `-d, --debug` - Debug output

**Interactive Mode** (`-i`): FZF-based browser with fuzzy search, preview, and multi-select. Requires `fzf` ([install](https://github.com/junegunn/fzf#installation)).

### 2. Discover Dynamic Sources

```bash
sumo-query discover-sources [OPTIONS]
```

Discovers source names from log data using search aggregation (`* | count by _sourceName, _sourceCategory`). This is not an official Sumo Logic API — it complements `list-sources` by finding runtime sources (CloudWatch, ECS, Lambda streams) that use dynamic `_sourceName` values.

**Options:**
- `-f, --from` - Start time (default: `-24h`)
- `-t, --to` - End time (default: `now`)
- `--filter` - Filter query (e.g., `_sourceCategory=*ecs*`)
- `-z, --time-zone` - Timezone (default: UTC)
- `-o, --output` - Save to file

**Examples:**

```bash
# Discover all sources from last 24 hours
sumo-query discover-sources

# Filter to ECS only
sumo-query discover-sources --filter '_sourceCategory=*ecs*'

# Last 7 days, save to file
sumo-query discover-sources -f '-7d' -o sources.json
```

### 3. List Collectors & Sources

```bash
# List collectors
sumo-query collectors [-o FILE]

# List static sources
sumo-query sources [-o FILE]
```

## Time Formats

```bash
# Relative (recommended)
-1h, -30m, -7d, now

# ISO 8601
2025-11-19T14:00:00

# Unix timestamp
1700000000

# Timezones
UTC, AEST, EST, America/New_York, Australia/Sydney, +10:00
```

See [examples/queries.md](examples/queries.md) for comprehensive query patterns.

## Ruby Library

```ruby
require 'sumologic'

client = Sumologic::Client.new(
  access_id: ENV['SUMO_ACCESS_ID'],
  access_key: ENV['SUMO_ACCESS_KEY']
)

# Search
client.search(query: 'error', from_time: '-1h', to_time: 'now')

# Discover sources
client.discover_dynamic_sources(from_time: '-24h', to_time: 'now')

# Metadata
client.list_collectors
client.list_all_sources
```

## Documentation

- [Query Examples](examples/queries.md) - Query patterns and examples
- [Quick Reference](docs/sdlc/7-maintain/tldr.md) - Command cheat sheet
- [Rate Limiting](docs/sdlc/4-develop/rate-limiting.md) - Performance tuning
- [Architecture](docs/sdlc/3-design/overview.md) - Design decisions

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## License

MIT License - see [LICENSE](LICENSE) file.

## Links

- [Issues](https://github.com/patrick204nqh/sumologic-query/issues)
- [Sumo Logic API Docs](https://help.sumologic.com/docs/api/search-job/)
- [Query Language](https://help.sumologic.com/docs/search/)
