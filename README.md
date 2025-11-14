# Sumo Logic Query Tool

> A lightweight Ruby CLI for querying Sumo Logic logs and metadata. Simple, fast, read-only access to your logs.

[![Gem Version](https://badge.fury.io/rb/sumologic-query.svg)](https://badge.fury.io/rb/sumologic-query)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## Why This Tool?

- **Minimal dependencies**: Uses only Ruby stdlib + Thor for CLI
- **Fast queries**: Efficient polling and automatic pagination
- **Simple interface**: Just query, get results, done
- **Read-only**: No write operations, perfect for safe log access
- **Modular architecture**: Clean separation of concerns (HTTP, Search, Metadata)
- **Metadata support**: List collectors and sources alongside log queries

All existing Ruby Sumo Logic gems are unmaintained (2-9 years dormant). This tool provides a fresh, minimal approach focused on querying logs and metadata.

## Installation

### Via RubyGems

```bash
gem install sumologic-query
```

### Via Homebrew

```bash
brew tap patrick204nqh/tap
brew install sumologic-query
```

### From Source

```bash
git clone https://github.com/patrick204nqh/sumologic-query.git
cd sumologic-query
bundle install
bundle exec rake install
```

## Quick Start

### 1. Set Up Credentials

Export your Sumo Logic API credentials:

```bash
export SUMO_ACCESS_ID="your_access_id"
export SUMO_ACCESS_KEY="your_access_key"
export SUMO_DEPLOYMENT="us2"  # Optional: us1, us2 (default), eu, au, etc.
```

**Getting credentials:**
1. Log in to Sumo Logic
2. Go to **Administration → Security → Access Keys**
3. Create a new access key or use existing
4. Copy the Access ID and Access Key

### 2. Run Your First Query

```bash
# Search logs
sumo-query search --query 'error' \
  --from '2025-11-13T14:00:00' \
  --to '2025-11-13T15:00:00' \
  --limit 10

# List collectors
sumo-query collectors

# List sources
sumo-query sources
```

## Usage

The CLI provides three main commands:

### Search Logs

```bash
sumo-query search --query "YOUR_QUERY" \
  --from "START_TIME" \
  --to "END_TIME" \
  [--output FILE] \
  [--limit N] \
  [--time-zone TZ]
```

**Required options:**
- `-q, --query QUERY` - Sumo Logic query string
- `-f, --from TIME` - Start time (ISO 8601 format)
- `-t, --to TIME` - End time (ISO 8601 format)

**Optional options:**
- `-z, --time-zone TZ` - Time zone (default: UTC)
- `-l, --limit N` - Limit number of messages
- `-o, --output FILE` - Save to file (default: stdout)
- `-d, --debug` - Enable debug output

### List Collectors

```bash
sumo-query collectors [--output FILE]
```

Lists all collectors in your account with status and metadata.

### List Sources

```bash
sumo-query sources [--output FILE]
```

Lists all sources from active collectors.

**See [examples/queries.md](examples/queries.md) for more query patterns and examples.**

## Ruby Library Usage

Use the library directly in your Ruby code:

```ruby
require 'sumologic'

# Initialize client
client = Sumologic::Client.new(
  access_id: ENV['SUMO_ACCESS_ID'],
  access_key: ENV['SUMO_ACCESS_KEY'],
  deployment: 'us2'
)

# Search logs
results = client.search(
  query: 'error',
  from_time: '2025-11-13T14:00:00',
  to_time: '2025-11-13T15:00:00',
  time_zone: 'UTC',
  limit: 1000
)

results.each do |message|
  puts message['map']['message']
end

# List collectors
collectors = client.list_collectors

# List all sources
sources = client.list_all_sources
```

**See [docs/api-reference.md](docs/api-reference.md) for complete API documentation.**

## Time Formats

Use ISO 8601 format for timestamps:

```bash
# UTC timestamps (default)
--from "2025-11-13T14:30:00" --to "2025-11-13T15:00:00"

# With timezone
--from "2025-11-13T14:30:00" --time-zone "America/New_York"

# Using shell helpers
--from "$(date -u -v-1H '+%Y-%m-%dT%H:%M:%S')"  # 1 hour ago
--to "$(date -u '+%Y-%m-%dT%H:%M:%S')"          # now
```

## Output Format

Results are returned as JSON:

```json
{
  "query": "error",
  "from": "2025-11-13T14:00:00",
  "to": "2025-11-13T15:00:00",
  "time_zone": "UTC",
  "message_count": 42,
  "messages": [
    {
      "map": {
        "_messagetime": "1731506400123",
        "_sourceCategory": "prod/api",
        "_sourceName": "api-server-01",
        "message": "Error processing request: timeout"
      }
    }
  ]
}
```

## Performance

Query execution time depends on data volume:

| Messages | Typical Time |
|----------|--------------|
| < 10K | 30-60 seconds |
| 10K-100K | 1-2 minutes |
| 100K+ | 2-5 minutes |

**Tips for faster queries:**
- Narrow your time range
- Add `_sourceCategory` filters
- Use `--limit` to cap results
- Use aggregation queries instead of raw messages

## Documentation

- **[Quick Reference (tldr)](docs/tldr.md)** - Concise command examples in tldr format
- **[Query Examples](examples/queries.md)** - Common query patterns and use cases
- **[API Reference](docs/api-reference.md)** - Complete Ruby library documentation
- **[Architecture](docs/architecture.md)** - How the tool works internally
- **[Troubleshooting](docs/troubleshooting.md)** - Common issues and solutions

## Development

See [CONTRIBUTING.md](CONTRIBUTING.md) for development setup, testing, and contribution guidelines.

Quick start:

```bash
# Clone and install
git clone https://github.com/patrick204nqh/sumologic-query.git
cd sumologic-query
bundle install

# Run tests
bundle exec rspec

# Run linter
bundle exec rubocop

# Test locally
bundle exec bin/sumo-query search --query "error" \
  --from "2025-11-13T14:00:00" \
  --to "2025-11-13T15:00:00"
```

## Contributing

Contributions are welcome! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for details.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

- **Issues**: [GitHub Issues](https://github.com/patrick204nqh/sumologic-query/issues)
- **Discussions**: [GitHub Discussions](https://github.com/patrick204nqh/sumologic-query/discussions)
- **Documentation**: [docs/](docs/)

## Resources

- **Sumo Logic API Docs**: https://help.sumologic.com/docs/api/search-job/
- **Query Language**: https://help.sumologic.com/docs/search/
- **Bug Reports**: https://github.com/patrick204nqh/sumologic-query/issues

---

**Note**: This tool provides read-only access to Sumo Logic logs. It does not modify any data or configuration.
