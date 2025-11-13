# Sumo Logic Query Tool

> A lightweight Ruby CLI for querying Sumo Logic logs quickly. Simple, fast, read-only access to your logs.

[![Gem Version](https://badge.fury.io/rb/sumologic-query.svg)](https://badge.fury.io/rb/sumologic-query)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## Why This Tool?

- **Zero dependencies**: Uses only Ruby stdlib - no external gems required
- **Fast queries**: Efficient polling and automatic pagination
- **Simple interface**: Just query, get results, done
- **Read-only**: No write operations, perfect for safe log access
- **Lightweight**: ~300 lines of code total

All existing Ruby Sumo Logic gems are unmaintained (2-9 years dormant). This tool provides a fresh, minimal approach focused solely on querying logs.

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
export SUMO_DEPLOYMENT="us2"  # Optional: us1, us2 (default), eu, au
```

**Getting credentials:**
1. Log in to Sumo Logic
2. Go to **Administration → Security → Access Keys**
3. Create a new access key or use existing
4. Copy the Access ID and Access Key

### 2. Run Your First Query

```bash
sumo-query --query 'error' \
  --from '2025-11-13T14:00:00' \
  --to '2025-11-13T15:00:00' \
  --limit 10
```

## Usage

### Basic Command Structure

```bash
sumo-query --query "YOUR_QUERY" \
  --from "START_TIME" \
  --to "END_TIME" \
  [--output FILE] \
  [--limit N] \
  [--time-zone TZ]
```

### Required Options

- `-q, --query QUERY` - Sumo Logic query string
- `-f, --from TIME` - Start time in ISO 8601 format
- `-t, --to TIME` - End time in ISO 8601 format

### Optional Options

- `-z, --time-zone TZ` - Time zone (default: UTC)
- `-l, --limit N` - Limit number of messages
- `-o, --output FILE` - Save results to file (default: stdout)
- `-d, --debug` - Enable debug output
- `-h, --help` - Show help message
- `-v, --version` - Show version

## Common Query Patterns

### Error Analysis

```bash
# Find all errors in a time window
sumo-query --query 'error' \
  --from '2025-11-13T14:00:00' \
  --to '2025-11-13T15:00:00' \
  --output errors.json

# Error timeline with 5-minute buckets
sumo-query --query 'error | timeslice 5m | count by _timeslice' \
  --from '2025-11-13T14:00:00' \
  --to '2025-11-13T15:00:00'
```

### Text Search

```bash
# Search for specific text
sumo-query --query '"connection timeout"' \
  --from '2025-11-13T14:00:00' \
  --to '2025-11-13T15:00:00'

# Case-insensitive search
sumo-query --query 'timeout OR failure OR exception' \
  --from '2025-11-13T14:00:00' \
  --to '2025-11-13T15:00:00'
```

### Filtering by Source

```bash
# Filter by source category
sumo-query --query '_sourceCategory=prod/api error' \
  --from '2025-11-13T14:00:00' \
  --to '2025-11-13T15:00:00'

# Multiple sources
sumo-query --query '(_sourceCategory=prod/api OR _sourceCategory=prod/web) AND error' \
  --from '2025-11-13T14:00:00' \
  --to '2025-11-13T15:00:00'
```

### Aggregation Queries

```bash
# Count by field
sumo-query --query '* | count by status_code' \
  --from '2025-11-13T14:00:00' \
  --to '2025-11-13T15:00:00'

# Top 10 slowest requests
sumo-query --query 'duration_ms > 1000 | sort by duration_ms desc | limit 10' \
  --from '2025-11-13T14:00:00' \
  --to '2025-11-13T15:00:00'
```

### Parsing and Field Extraction

```bash
# Parse specific fields
sumo-query --query '* | parse "user_id=* " as user_id | count by user_id' \
  --from '2025-11-13T14:00:00' \
  --to '2025-11-13T15:00:00'
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

## Time Formats

Use ISO 8601 format for timestamps:

```bash
# UTC timestamps (default)
--from "2025-11-13T14:30:00"
--to "2025-11-13T15:00:00"

# With timezone
--from "2025-11-13T14:30:00" --time-zone "America/New_York"

# Alternative: Relative times (in your shell)
--from "$(date -u -v-1H '+%Y-%m-%dT%H:%M:%S')"  # 1 hour ago
--to "$(date -u '+%Y-%m-%dT%H:%M:%S')"         # now
```

## Performance

Query execution time depends on data volume:

- **Small queries** (<10K messages): ~30-60 seconds
- **Medium queries** (10K-100K): ~1-2 minutes
- **Large queries** (100K+): ~2-5 minutes

Default timeout: 5 minutes

To improve performance:
- Narrow your time range
- Add specific `_sourceCategory` filters
- Use `--limit` to cap results
- Use aggregation queries instead of fetching raw messages

## Troubleshooting

### Authentication Error

```
Error: SUMO_ACCESS_ID not set
```

**Solution**: Export your credentials:
```bash
export SUMO_ACCESS_ID="your_access_id"
export SUMO_ACCESS_KEY="your_access_key"
```

### Timeout Error

```
Timeout Error: Search job timed out after 300 seconds
```

**Solutions**:
- Reduce time range
- Add more specific filters (`_sourceCategory`, `_sourceName`)
- Use `--limit` to cap results
- Consider using aggregation instead of raw messages

### Empty Results

```json
{
  "message_count": 0,
  "messages": []
}
```

**Check**:
- Time range matches your expected data
- Query syntax is valid (test in Sumo Logic UI first)
- Source categories are correct
- Time zone is correct (default is UTC)

### Rate Limit Error

```
HTTP 429: Rate limit exceeded
```

**Solution**: Wait 1-2 minutes between queries. Sumo Logic enforces rate limits per account.

## Development

### Running Tests

```bash
bundle install
bundle exec rake spec
```

### Code Quality

```bash
bundle exec rubocop
bundle exec rubocop -A  # Auto-fix issues
```

### Running Locally

```bash
# Without installing
bundle exec bin/sumo-query --query "error" \
  --from "2025-11-13T14:00:00" \
  --to "2025-11-13T15:00:00"

# With debug output
SUMO_DEBUG=1 bundle exec bin/sumo-query --query "error" \
  --from "2025-11-13T14:00:00" \
  --to "2025-11-13T15:00:00"
```

## How It Works

This tool uses the Sumo Logic Search Job API:

1. **Create Job** - POST to `/api/v1/search/jobs` with your query
2. **Poll Status** - GET `/api/v1/search/jobs/:id` every 20 seconds until complete
3. **Fetch Messages** - GET `/api/v1/search/jobs/:id/messages` (automatically paginated)
4. **Clean Up** - DELETE `/api/v1/search/jobs/:id`

All steps are handled automatically. You just provide the query and get results.

## API Reference

### Ruby Library Usage

You can also use the library directly in your Ruby code:

```ruby
require 'sumologic'

client = Sumologic::Client.new(
  access_id: 'your_access_id',
  access_key: 'your_access_key',
  deployment: 'us2'
)

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

## Resources

- **Sumo Logic API Docs**: https://help.sumologic.com/docs/api/search-job/
- **Query Language**: https://help.sumologic.com/docs/search/
- **Bug Reports**: https://github.com/patrick204nqh/sumologic-query/issues
- **Feature Requests**: https://github.com/patrick204nqh/sumologic-query/issues

## Support

- **Issues**: [GitHub Issues](https://github.com/patrick204nqh/sumologic-query/issues)
- **Discussions**: [GitHub Discussions](https://github.com/patrick204nqh/sumologic-query/discussions)

---

**Note**: This tool provides read-only access to Sumo Logic logs. It does not modify any data or configuration.
