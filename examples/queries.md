# Query Examples

Common patterns for querying Sumo Logic logs.

> **Note:** For detailed time format options (relative times, timezones, Unix timestamps), see [time-formats.md](time-formats.md)

## Basic Search

```bash
# Simple text search (last hour)
sumo-query search -q 'error' -f '-1h' -t 'now'

# Search with exact phrase
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

## Metadata Operations

```bash
# List all collectors
sumo-query collectors --output collectors.json

# List all sources
sumo-query sources --output sources.json

# Filter sources with jq
sumo-query sources | jq '.[] | select(.sources[].name | contains("production"))'
```

## Output Handling

```bash
# Save to file (directories auto-created)
sumo-query search -q 'error' -f '-1h' -t 'now' -o results.json

# Nested directories
sumo-query search -q 'error' -f '-7d' -t 'now' -o logs/weekly/errors.json

# Limit results
sumo-query search -q 'error' -f '-1h' -t 'now' --limit 100

# Format with jq
sumo-query search -q 'error' -f '-1h' -t 'now' | \
  jq '.messages[] | {time: .map._messagetime, message: .map.message}'
```

## Timezone Examples

```bash
# Default UTC
sumo-query search -q 'error' -f '-1h' -t 'now'

# Specify timezone
sumo-query search -q 'error' -f '-1h' -t 'now' -z 'America/New_York'

# Australian timezone
sumo-query search -q 'error' -f '-1h' -t 'now' -z 'AEST'
```

See [time-formats.md](time-formats.md) for comprehensive timezone options.

## Tips

- **Narrow time ranges** for faster queries
- **Add source filters** to reduce data volume
- **Use aggregations** instead of raw messages when possible
- **Test queries** in Sumo Logic UI first
- **Use `--limit`** for large result sets

For full query language documentation, see [Sumo Logic Search Reference](https://help.sumologic.com/docs/search/).
