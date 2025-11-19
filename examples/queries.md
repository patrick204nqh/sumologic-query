# Query Examples

Common patterns for querying Sumo Logic logs.

## Time Formats

### Relative Time (Recommended)

```bash
# Last 30 minutes
sumo-query search -q 'error' -f '-30m' -t 'now'

# Last hour
sumo-query search -q 'error' -f '-1h' -t 'now'

# Last 7 days
sumo-query search -q 'error' -f '-7d' -t 'now' --limit 100
```

**Supported units:** `s` (seconds), `m` (minutes), `h` (hours), `d` (days), `w` (weeks), `M` (months), `now`

### Other Formats

```bash
# ISO 8601
sumo-query search -q 'error' -f '2025-11-13T14:00:00' -t '2025-11-13T15:00:00'

# Unix timestamp
sumo-query search -q 'error' -f '1700000000' -t 'now'

# Mix formats
sumo-query search -q 'error' -f '-24h' -t '2025-11-19T12:00:00'
```

### Timezones

```bash
# US timezones
sumo-query search -q 'error' -f '-1h' -t 'now' -z 'EST'
sumo-query search -q 'error' -f '-1h' -t 'now' -z 'America/New_York'

# Australian timezones
sumo-query search -q 'error' -f '-1h' -t 'now' -z 'AEST'
sumo-query search -q 'error' -f '-1h' -t 'now' -z 'Australia/Sydney'

# Other formats: PST, CST, MST, ACST, AWST, Europe/London, +10:00
```

## Basic Search

```bash
# Simple text search
sumo-query search -q 'error' -f '-1h' -t 'now'

# Exact phrase
sumo-query search -q '"connection timeout"' -f '-30m' -t 'now'

# Multiple keywords
sumo-query search -q 'error AND database' -f '-2h' -t 'now'
```

## Filtering

```bash
# Filter by source category
sumo-query search -q '_sourceCategory=prod/api error' -f '-1h' -t 'now'

# Filter by source name
sumo-query search -q '_sourceName=api-server-01 error' -f '-30m' -t 'now'

# Multiple sources
sumo-query search -q '(_sourceCategory=prod/api OR _sourceCategory=prod/web) AND error' -f '-2h' -t 'now'
```

## Aggregations

```bash
# Count messages
sumo-query search -q 'error | count' -f '-1h' -t 'now'

# Count by field
sumo-query search -q '* | count by status_code' -f '-1h' -t 'now'

# Time series (5-minute buckets)
sumo-query search -q 'error | timeslice 5m | count by _timeslice' -f '-24h' -t 'now'
```

## Parsing and Extraction

```bash
# Parse fields
sumo-query search -q '* | parse "user_id=* " as user_id | count by user_id' -f '-1h' -t 'now'

# Extract JSON fields
sumo-query search -q '* | json field=_raw "user.id" as user_id' -f '-1h' -t 'now'
```

## Output Options

```bash
# Save to file (directories auto-created)
sumo-query search -q 'error' -f '-1h' -t 'now' -o results.json

# Nested directories
sumo-query search -q 'error' -f '-7d' -t 'now' -o logs/weekly/errors.json

# Limit results
sumo-query search -q 'error' -f '-1h' -t 'now' --limit 100

# Interactive mode
sumo-query search -q 'error' -f '-1h' -t 'now' -i

# Format with jq
sumo-query search -q 'error' -f '-1h' -t 'now' | \
  jq '.messages[] | {time: .map._messagetime, message: .map.message}'
```

## Metadata Operations

```bash
# List all collectors
sumo-query collectors -o collectors.json

# List all sources
sumo-query sources -o sources.json

# Filter sources with jq
sumo-query sources | jq '.[] | select(.sources[].name | contains("production"))'
```

## Common Patterns

```bash
# Last hour errors in production
sumo-query search -q '_sourceCategory=prod/* error' -f '-1h' -t 'now'

# Today's business hours (9 AM - 5 PM Sydney time)
sumo-query search -q 'error' \
  -f '2025-11-19T09:00:00' \
  -t '2025-11-19T17:00:00' \
  -z 'Australia/Sydney'

# Last 24 hours with rate limit safety
export SUMO_MAX_WORKERS=2
sumo-query search -q 'error' -f '-24h' -t 'now' -o daily-errors.json
```

## Ruby API

```ruby
require 'sumologic'
require 'sumologic/utils/time_parser'

client = Sumologic::Client.new(
  access_id: ENV['SUMO_ACCESS_ID'],
  access_key: ENV['SUMO_ACCESS_KEY']
)

# Search with relative times
from_time = Sumologic::Utils::TimeParser.parse('-1h')
to_time = Sumologic::Utils::TimeParser.parse('now')

results = client.search(
  query: 'error',
  from_time: from_time,
  to_time: to_time,
  time_zone: 'UTC',
  limit: 1000
)
```

## Tips

- **Use relative times** for ad-hoc queries (`-1h`, `-30m`)
- **Narrow time ranges** for faster queries
- **Add source filters** to reduce data volume
- **Use aggregations** instead of raw messages when possible
- **Use `--limit`** for large result sets
- **Test queries** in Sumo Logic UI first

For full query language documentation, see [Sumo Logic Search Reference](https://help.sumologic.com/docs/search/).
