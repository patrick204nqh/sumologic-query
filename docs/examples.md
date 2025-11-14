# Query Examples

This guide provides common query patterns and examples for using the Sumo Logic Query Tool.

## Table of Contents

- [Error Analysis](#error-analysis)
- [Text Search](#text-search)
- [Filtering by Source](#filtering-by-source)
- [Aggregation Queries](#aggregation-queries)
- [Parsing and Field Extraction](#parsing-and-field-extraction)
- [Metadata Operations](#metadata-operations)

## Error Analysis

### Find all errors in a time window

```bash
sumo-query search --query 'error' \
  --from '2025-11-13T14:00:00' \
  --to '2025-11-13T15:00:00' \
  --output errors.json
```

### Error timeline with 5-minute buckets

```bash
sumo-query search --query 'error | timeslice 5m | count by _timeslice' \
  --from '2025-11-13T14:00:00' \
  --to '2025-11-13T15:00:00'
```

### Errors by severity

```bash
sumo-query search --query 'error OR fatal | parse "level=*" as level | count by level' \
  --from '2025-11-13T14:00:00' \
  --to '2025-11-13T15:00:00'
```

## Text Search

### Search for specific text

```bash
sumo-query search --query '"connection timeout"' \
  --from '2025-11-13T14:00:00' \
  --to '2025-11-13T15:00:00'
```

### Case-insensitive search

```bash
sumo-query search --query 'timeout OR failure OR exception' \
  --from '2025-11-13T14:00:00' \
  --to '2025-11-13T15:00:00'
```

### Multiple keyword search

```bash
sumo-query search --query 'database AND (slow OR timeout)' \
  --from '2025-11-13T14:00:00' \
  --to '2025-11-13T15:00:00'
```

## Filtering by Source

### Filter by source category

```bash
sumo-query search --query '_sourceCategory=prod/api error' \
  --from '2025-11-13T14:00:00' \
  --to '2025-11-13T15:00:00'
```

### Multiple sources

```bash
sumo-query search --query '(_sourceCategory=prod/api OR _sourceCategory=prod/web) AND error' \
  --from '2025-11-13T14:00:00' \
  --to '2025-11-13T15:00:00'
```

### Filter by source name

```bash
sumo-query search --query '_sourceName=api-server-01 error' \
  --from '2025-11-13T14:00:00' \
  --to '2025-11-13T15:00:00'
```

## Aggregation Queries

### Count by field

```bash
sumo-query search --query '* | count by status_code' \
  --from '2025-11-13T14:00:00' \
  --to '2025-11-13T15:00:00'
```

### Top 10 slowest requests

```bash
sumo-query search --query 'duration_ms > 1000 | sort by duration_ms desc | limit 10' \
  --from '2025-11-13T14:00:00' \
  --to '2025-11-13T15:00:00'
```

### Average response time by endpoint

```bash
sumo-query search --query 'api | parse "endpoint=* " as endpoint | parse "duration=* " as duration | avg(duration) by endpoint' \
  --from '2025-11-13T14:00:00' \
  --to '2025-11-13T15:00:00'
```

### Count unique users

```bash
sumo-query search --query '* | parse "user_id=* " as user_id | count_distinct(user_id)' \
  --from '2025-11-13T14:00:00' \
  --to '2025-11-13T15:00:00'
```

## Parsing and Field Extraction

### Parse specific fields

```bash
sumo-query search --query '* | parse "user_id=* " as user_id | count by user_id' \
  --from '2025-11-13T14:00:00' \
  --to '2025-11-13T15:00:00'
```

### Parse multiple fields

```bash
sumo-query search --query '* | parse "user=* method=* path=*" as user, method, path | count by method, path' \
  --from '2025-11-13T14:00:00' \
  --to '2025-11-13T15:00:00'
```

### Extract JSON fields

```bash
sumo-query search --query '* | json field=_raw "user.id" as user_id | count by user_id' \
  --from '2025-11-13T14:00:00' \
  --to '2025-11-13T15:00:00'
```

### Filter by extracted field

```bash
sumo-query search --query '* | parse "status=* " as status | where status="500" | count' \
  --from '2025-11-13T14:00:00' \
  --to '2025-11-13T15:00:00'
```

## Metadata Operations

### List all collectors with their status

```bash
sumo-query collectors --output collectors.json
```

### List all sources from active collectors

```bash
sumo-query sources --output sources.json
```

### Find specific sources (using jq for filtering)

```bash
# Filter for production sources
sumo-query sources | jq '.[] | select(.sources[].name | contains("production"))'

# Count sources per collector
sumo-query sources | jq '.[] | {collector: .collector.name, source_count: (.sources | length)}'

# Find specific source type
sumo-query sources | jq '.[] | select(.sources[].sourceType == "LocalFile")'
```

### Combine metadata with queries

```bash
# First, get your source categories
sumo-query sources | jq -r '.[].sources[].category' | sort -u > categories.txt

# Then query specific categories
sumo-query search --query '_sourceCategory=prod/api error' \
  --from '2025-11-13T14:00:00' \
  --to '2025-11-13T15:00:00'
```

## Time-based Queries

### Last hour of logs

```bash
sumo-query search --query 'error' \
  --from "$(date -u -v-1H '+%Y-%m-%dT%H:%M:%S')" \
  --to "$(date -u '+%Y-%m-%dT%H:%M:%S')"
```

### Specific day

```bash
sumo-query search --query 'error' \
  --from '2025-11-13T00:00:00' \
  --to '2025-11-13T23:59:59'
```

### Business hours only (9 AM - 5 PM)

```bash
sumo-query search --query 'error' \
  --from '2025-11-13T09:00:00' \
  --to '2025-11-13T17:00:00' \
  --time-zone 'America/New_York'
```

## Advanced Patterns

### Transaction analysis

```bash
sumo-query search --query 'transaction | parse "transaction_id=* " as txn_id | parse "duration=* " as duration | where duration > 5000 | count by txn_id' \
  --from '2025-11-13T14:00:00' \
  --to '2025-11-13T15:00:00'
```

### Trend analysis

```bash
sumo-query search --query 'error | timeslice 1h | count by _timeslice | compare with timeshift 1d' \
  --from '2025-11-13T00:00:00' \
  --to '2025-11-13T23:59:59'
```

### Outlier detection

```bash
sumo-query search --query '* | parse "response_time=* " as rt | outlier rt by service' \
  --from '2025-11-13T14:00:00' \
  --to '2025-11-13T15:00:00'
```

## Output and Formatting

### Save to file

```bash
sumo-query search --query 'error' \
  --from '2025-11-13T14:00:00' \
  --to '2025-11-13T15:00:00' \
  --output errors.json
```

### Format with jq

```bash
sumo-query search --query 'error' \
  --from '2025-11-13T14:00:00' \
  --to '2025-11-13T15:00:00' | \
  jq '.messages[] | {time: .map._messagetime, message: .map.message}'
```

### Extract specific fields

```bash
sumo-query search --query 'error' \
  --from '2025-11-13T14:00:00' \
  --to '2025-11-13T15:00:00' | \
  jq -r '.messages[] | .map.message'
```

## Performance Tips

1. **Narrow time ranges**: Smaller time windows query faster
2. **Use specific filters**: Add `_sourceCategory` or `_sourceName` filters
3. **Limit results**: Use `--limit` for large result sets
4. **Use aggregations**: Aggregate data instead of fetching raw messages
5. **Avoid wildcards**: Specific terms query faster than wildcards

## See Also

- [Architecture](architecture.md) - Understanding how queries are executed
- [API Reference](api-reference.md) - Using the Ruby library directly
- [Troubleshooting](troubleshooting.md) - Common issues and solutions
