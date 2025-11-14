# Query Examples

Common patterns for querying Sumo Logic logs.

## Basic Search

```bash
# Simple text search
sumo-query search --query 'error' \
  --from '2025-11-13T14:00:00' \
  --to '2025-11-13T15:00:00'

# Search with exact phrase
sumo-query search --query '"connection timeout"' \
  --from '2025-11-13T14:00:00' \
  --to '2025-11-13T15:00:00'

# Multiple keywords
sumo-query search --query 'error AND database' \
  --from '2025-11-13T14:00:00' \
  --to '2025-11-13T15:00:00'
```

## Filtering

```bash
# Filter by source category
sumo-query search --query '_sourceCategory=prod/api error' \
  --from '2025-11-13T14:00:00' \
  --to '2025-11-13T15:00:00'

# Filter by source name
sumo-query search --query '_sourceName=api-server-01 error' \
  --from '2025-11-13T14:00:00' \
  --to '2025-11-13T15:00:00'

# Multiple sources
sumo-query search --query '(_sourceCategory=prod/api OR _sourceCategory=prod/web) AND error' \
  --from '2025-11-13T14:00:00' \
  --to '2025-11-13T15:00:00'
```

## Aggregations

```bash
# Count messages
sumo-query search --query 'error | count' \
  --from '2025-11-13T14:00:00' \
  --to '2025-11-13T15:00:00'

# Count by field
sumo-query search --query '* | count by status_code' \
  --from '2025-11-13T14:00:00' \
  --to '2025-11-13T15:00:00'

# Time series (5-minute buckets)
sumo-query search --query 'error | timeslice 5m | count by _timeslice' \
  --from '2025-11-13T14:00:00' \
  --to '2025-11-13T15:00:00'
```

## Parsing and Extraction

```bash
# Parse fields
sumo-query search --query '* | parse "user_id=* " as user_id | count by user_id' \
  --from '2025-11-13T14:00:00' \
  --to '2025-11-13T15:00:00'

# Extract JSON fields
sumo-query search --query '* | json field=_raw "user.id" as user_id' \
  --from '2025-11-13T14:00:00' \
  --to '2025-11-13T15:00:00'
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
# Save to file
sumo-query search --query 'error' \
  --from '2025-11-13T14:00:00' \
  --to '2025-11-13T15:00:00' \
  --output results.json

# Limit results
sumo-query search --query 'error' \
  --from '2025-11-13T14:00:00' \
  --to '2025-11-13T15:00:00' \
  --limit 100

# Format with jq
sumo-query search --query 'error' \
  --from '2025-11-13T14:00:00' \
  --to '2025-11-13T15:00:00' | \
  jq '.messages[] | {time: .map._messagetime, message: .map.message}'
```

## Time Zones

```bash
# Default UTC
sumo-query search --query 'error' \
  --from '2025-11-13T14:00:00' \
  --to '2025-11-13T15:00:00'

# Specify timezone
sumo-query search --query 'error' \
  --from '2025-11-13T09:00:00' \
  --to '2025-11-13T17:00:00' \
  --time-zone 'America/New_York'
```

## Tips

- **Narrow time ranges** for faster queries
- **Add source filters** to reduce data volume
- **Use aggregations** instead of raw messages when possible
- **Test queries** in Sumo Logic UI first
- **Use `--limit`** for large result sets

For full query language documentation, see [Sumo Logic Search Reference](https://help.sumologic.com/docs/search/).
