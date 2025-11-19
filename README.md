# Sumo Logic Query Tool

> A lightweight Ruby CLI for querying Sumo Logic logs and metadata. Simple, fast, read-only access to your logs.

[![Gem Version](https://badge.fury.io/rb/sumologic-query.svg)](https://badge.fury.io/rb/sumologic-query)
[![Downloads](https://img.shields.io/gem/dt/sumologic-query.svg)](https://rubygems.org/gems/sumologic-query)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## Why This Tool?

- **Intuitive time parsing**: Use relative times like `-1h`, `-30m`, or `now` - no more calculating timestamps!
- **Flexible timezone support**: US, Australian, and IANA timezone formats supported
- **Minimal dependencies**: Uses only Ruby stdlib + Thor for CLI
- **Fast queries**: Efficient polling and automatic pagination
- **Interactive mode**: Explore logs with FZF-powered fuzzy search and preview
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
# Search logs from last hour (easy!)
sumo-query search --query 'error' --from '-1h' --to 'now' --limit 10

# Search logs from last 30 minutes
sumo-query search --query 'error' --from '-30m' --to 'now'

# Or use ISO 8601 format
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
  [--time-zone TZ] \
  [--interactive]
```

**Required options:**
- `-q, --query QUERY` - Sumo Logic query string
- `-f, --from TIME` - Start time (ISO 8601 format)
- `-t, --to TIME` - End time (ISO 8601 format)

**Optional options:**
- `-i, --interactive` - Launch interactive browser with FZF
- `-z, --time-zone TZ` - Time zone (default: UTC)
- `-l, --limit N` - Limit number of messages
- `-o, --output FILE` - Save to file (default: stdout)
- `-d, --debug` - Enable debug output

### Interactive Mode 🚀

Explore your logs interactively with a powerful FZF-based interface:

```bash
# Launch interactive mode - last hour
sumo-query search --query 'error' --from '-1h' --to 'now' --interactive

# Last 30 minutes with shorthand
sumo-query search -q 'error' -f '-30m' -t 'now' -i

# Or use ISO 8601 format
sumo-query search -q 'error' -f '2025-11-13T14:00:00' -t '2025-11-13T15:00:00' -i
```

**Features:**
- 🔍 Fuzzy search across all message fields
- 👁️ Live preview with full JSON details
- 🎨 Color-coded log levels (ERROR, WARN, INFO)
- ⌨️ Keyboard shortcuts for quick actions
- 📋 Multi-select and batch operations
- 💾 Export selected messages

**Keybindings:**
- `Enter` - Toggle selection (mark/unmark message)
- `Tab` - Open current message in pager (copyable view)
- `Ctrl-S` - Save selected messages to `sumo-selected.txt` and exit
- `Ctrl-Y` - Copy selected messages to clipboard and exit
- `Ctrl-E` - Export selected messages to `sumo-export.jsonl` and exit
- `Ctrl-A` - Select all messages
- `Ctrl-D` - Deselect all messages
- `Ctrl-/` - Toggle preview pane
- `Ctrl-Q` - Quit without saving

**Requirements:**
- Install FZF: `brew install fzf` (macOS) or `apt-get install fzf` (Linux)
- See: https://github.com/junegunn/fzf#installation

### Time Format Examples

Combine relative times with timezones for powerful queries:

```bash
# Last hour in Sydney time
sumo-query search -q 'error' -f '-1h' -t 'now' -z AEST

# Last 30 minutes in US Eastern time
sumo-query search -q 'error' -f '-30m' -t 'now' -z EST

# Last 7 days with output to file (directories auto-created)
sumo-query search -q 'error' -f '-7d' -t 'now' -o logs/weekly/errors.json

# Mix relative and ISO 8601 formats
sumo-query search -q 'error' -f '-24h' -t '2025-11-19T12:00:00'

# Unix timestamps from last hour to now
sumo-query search -q 'error' -f '1700000000' -t 'now'
```

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


## Ruby Library Usage

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

# List collectors and sources
collectors = client.list_collectors
sources = client.list_all_sources
```

**Time parsing utilities:**

```ruby
require 'sumologic/utils/time_parser'

# Parse relative times and timezones
from_time = Sumologic::Utils::TimeParser.parse('-1h')
timezone = Sumologic::Utils::TimeParser.parse_timezone('AEST')
```


## Time Formats

Multiple time formats are supported:

```bash
# Relative time (easiest!)
sumo-query search -q 'error' -f '-1h' -t 'now'
sumo-query search -q 'error' -f '-30m' -t 'now'

# ISO 8601
sumo-query search -q 'error' -f '2025-11-13T14:00:00' -t '2025-11-13T15:00:00'

# Unix timestamps
sumo-query search -q 'error' -f '1700000000' -t 'now'

# With timezones
sumo-query search -q 'error' -f '-1h' -t 'now' -z 'AEST'
sumo-query search -q 'error' -f '-1h' -t 'now' -z 'America/New_York'
```

**Supported time units:** `s`, `m`, `h`, `d`, `w`, `M`, `now`

**Supported timezones:** IANA names (`UTC`, `America/New_York`, `Australia/Sydney`), US abbreviations (`EST`, `PST`), Australian abbreviations (`AEST`, `ACST`, `AWST`), UTC offsets (`+10:00`)

See [examples/time-formats.md](examples/time-formats.md) for comprehensive examples.

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

- **[Quick Reference (tldr)](docs/tldr.md)** - Concise command examples
- **[Query Examples](examples/queries.md)** - Common query patterns
- **[Time Format Examples](examples/time-formats.md)** - Time parsing and timezone options
- **[Architecture](docs/architecture/)** - Design and architecture decisions

## Development

See [CONTRIBUTING.md](CONTRIBUTING.md) for development setup, testing, and contribution guidelines.

Quick start:

```bash
# Clone and install
git clone https://github.com/patrick204nqh/sumologic-query.git
cd sumologic-query
bundle install

# Run tests (73+ specs including time parser tests)
bundle exec rspec

# Run linter
bundle exec rubocop

# Test locally with new time formats
bundle exec bin/sumo-query search --query "error" \
  --from "-1h" --to "now"

# Test with timezone support
bundle exec bin/sumo-query search --query "error" \
  --from "-30m" --to "now" --time-zone "AEST"
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
