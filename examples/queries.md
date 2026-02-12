# Query Examples

Common patterns for querying Sumo Logic logs.

## Time Formats

```bash
# Relative (recommended)
sumo-query search -q 'error' -f '-1h' -t 'now'
sumo-query search -q 'error' -f '-30m' -t 'now'
sumo-query search -q 'error' -f '-7d' -t 'now'

# Units: s (seconds), m (minutes), h (hours), d (days), w (weeks), M (months)

# ISO 8601
sumo-query search -q 'error' -f '2025-11-19T14:00:00' -t '2025-11-19T15:00:00'

# Unix timestamp
sumo-query search -q 'error' -f '1700000000' -t 'now'

# With timezones
sumo-query search -q 'error' -f '-1h' -t 'now' -z 'AEST'
sumo-query search -q 'error' -f '-1h' -t 'now' -z 'America/New_York'
```

## Search Patterns

```bash
# Basic search
sumo-query search -q 'error' -f '-1h' -t 'now'

# Exact phrase
sumo-query search -q '"connection timeout"' -f '-1h' -t 'now'

# Boolean operators
sumo-query search -q 'error AND database' -f '-1h' -t 'now'
sumo-query search -q '(error OR warning) AND prod' -f '-1h' -t 'now'

# Filter by category
sumo-query search -q '_sourceCategory=prod/api error' -f '-1h' -t 'now'

# Filter by source name
sumo-query search -q '_sourceName=api-server-01 error' -f '-1h' -t 'now'
```

## Aggregations

```bash
# Count
sumo-query search -q 'error | count' -f '-1h' -t 'now'

# Count by field
sumo-query search -q '* | count by status_code' -f '-1h' -t 'now'

# Time series
sumo-query search -q 'error | timeslice 5m | count by _timeslice' -f '-24h' -t 'now'

# Parse and aggregate
sumo-query search -q '* | parse "user_id=* " as user_id | count by user_id' -f '-1h' -t 'now'
```

## Discover Dynamic Sources

Find CloudWatch/ECS/Lambda source names from log data:

```bash
# Discover all sources (last 24h)
sumo-query discover-source-metadata

# Last 7 days
sumo-query discover-source-metadata -f '-7d'

# Filter to ECS only
sumo-query discover-source-metadata --filter '_sourceCategory=*ecs*'

# Filter to Lambda
sumo-query discover-source-metadata --filter '_sourceCategory=lambda/*'

# Save to file
sumo-query discover-source-metadata -o sources.json

# With timezone
sumo-query discover-source-metadata -f '-24h' -z 'Australia/Sydney'
```

**Output example:**

```json
{
  "total_sources": 247,
  "sources": [
    {
      "name": "service/web/3ae03bcb849c4cfd8da5d159c39e6a2a",
      "category": "production/ecs",
      "message_count": 70904266
    }
  ]
}
```

**Use cases:**
- Find active CloudWatch log streams
- Discover ECS task IDs by activity
- Identify Lambda execution streams
- Build targeted queries
- Debug missing logs

## Metadata

```bash
# List collectors
sumo-query list-collectors -o collectors.json

# List static sources
sumo-query list-sources -o sources.json

# Filter with jq
sumo-query list-sources | jq '.data[] | select(.sources[].category | contains("production"))'
```

## Output Options

```bash
# Save to file
sumo-query search -q 'error' -f '-1h' -t 'now' -o results.json

# Limit results
sumo-query search -q 'error' -f '-1h' -t 'now' --limit 100

# Interactive mode (FZF)
sumo-query search -q 'error' -f '-1h' -t 'now' -i

# Format with jq
sumo-query search -q 'error' -f '-1h' -t 'now' | jq '.messages[].map.message'
```

## Ruby API

```ruby
require 'sumologic'

client = Sumologic::Client.new(
  access_id: ENV['SUMO_ACCESS_ID'],
  access_key: ENV['SUMO_ACCESS_KEY']
)

# Search logs
results = client.search(
  query: 'error',
  from_time: '-1h',
  to_time: 'now',
  limit: 1000
)

# Discover source metadata
sources = client.discover_source_metadata(
  from_time: '-24h',
  to_time: 'now',
  filter: '_sourceCategory=*ecs*'
)

puts "Found #{sources['total_sources']} sources"
sources['sources'].first(10).each do |s|
  puts "#{s['name']}: #{s['message_count']} messages"
end

# Metadata
collectors = client.list_collectors
sources = client.list_all_sources
```

## Tips

- Use relative times for ad-hoc queries (`-1h`, `-30m`)
- Narrow time ranges for faster queries
- Add source filters to reduce data volume
- Use aggregations instead of raw messages when possible
- Test queries in Sumo Logic UI first

See [Sumo Logic Search Reference](https://help.sumologic.com/docs/search/) for full query syntax.
