# Sumo Logic Query Tool

> A lightweight Ruby CLI for querying Sumo Logic logs and metadata. Simple, fast, read-only.

[![Gem Version](https://badge.fury.io/rb/sumologic-query.svg)](https://badge.fury.io/rb/sumologic-query)
[![Downloads](https://img.shields.io/gem/dt/sumologic-query.svg)](https://rubygems.org/gems/sumologic-query)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## Install

```bash
gem install sumologic-query

# or via Homebrew
brew tap patrick204nqh/tap && brew install sumologic-query
```

## Setup

```bash
export SUMO_ACCESS_ID="your_access_id"
export SUMO_ACCESS_KEY="your_access_key"
export SUMO_DEPLOYMENT="us2"  # us1, us2 (default), eu, au
```

Get credentials: Sumo Logic → **Administration → Security → Access Keys**

## Usage

```bash
# Search logs
sumo-query search -q 'error' -f '-1h' -t 'now' -l 100

# Search with aggregation
sumo-query search -q '* | count by _sourceCategory' -f '-1h' -t 'now' -a

# Interactive mode (requires fzf)
sumo-query search -q 'error' -f '-1h' -t 'now' -i

# Discover dynamic sources (CloudWatch/ECS/Lambda)
sumo-query discover-source-metadata -f '-7d' -k 'nginx'

# Monitors and health
sumo-query list-monitors -s Critical
sumo-query list-health-events

# Infrastructure
sumo-query list-collectors
sumo-query list-sources --collector "my-service"
sumo-query list-dashboards
sumo-query list-folders --tree

# Content, fields, apps
sumo-query get-content -p "/Library/Users/me/My Search"
sumo-query list-fields
sumo-query list-apps
```

Run `sumo-query help` or `sumo-query help <command>` for all flags.

## Time Formats

```bash
-1h, -30m, -7d, -1h30m, now         # Relative (recommended)
2025-11-19T14:00:00                   # ISO 8601
1700000000                            # Unix timestamp
-z America/New_York                   # Timezone (UTC, EST, AEST, IANA, +HH:MM)
```

## Ruby Library

```ruby
require 'sumologic'

client = Sumologic::Client.new(
  access_id: ENV['SUMO_ACCESS_ID'],
  access_key: ENV['SUMO_ACCESS_KEY']
)

client.search(query: 'error', from_time: '-1h', to_time: 'now')
client.discover_source_metadata(from_time: '-24h', to_time: 'now')
client.list_collectors
client.list_all_sources
```

## Documentation

- [Query Examples](examples/queries.md) - Search patterns and aggregations
- [Interactive Mode](docs/sdlc/7-maintain/interactive-demo.md) - FZF browser guide
- [Rate Limiting](docs/sdlc/4-develop/rate-limiting.md) - API limits and tuning
- [Architecture](docs/sdlc/3-design/overview.md) - Design decisions and ADRs

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).

## License

MIT - see [LICENSE](LICENSE).

## Links

- [Issues](https://github.com/patrick204nqh/sumologic-query/issues)
- [Sumo Logic API Docs](https://help.sumologic.com/docs/api/search-job/)
- [Query Language](https://help.sumologic.com/docs/search/)
