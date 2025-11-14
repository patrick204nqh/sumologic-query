# Example Queries

This document provides common query patterns for the Sumo Logic Query Tool.

## Commands Overview

```bash
# Search logs
sumo-query search --query 'error' --from '2025-11-13T14:00:00' --to '2025-11-13T15:00:00'

# List collectors
sumo-query list-collectors

# List all sources
sumo-query list-sources

# List sources for specific collector
sumo-query list-sources --collector-id 12345
```

## Search Examples

### Basic Text Search

Search for any occurrence of "error":
```bash
sumo-query search --query 'error' \
  --from '2025-11-13T14:00:00' \
  --to '2025-11-13T15:00:00'
```

### Case-Insensitive Search

```bash
sumo-query search --query 'Error OR ERROR OR error' \
  --from '2025-11-13T14:00:00' \
  --to '2025-11-13T15:00:00'
```

### Multiple Terms

```bash
sumo-query search --query 'error AND timeout' \
  --from '2025-11-13T14:00:00' \
  --to '2025-11-13T15:00:00'
```

### Exact Phrase

```bash
sumo-query search --query '"connection refused"' \
  --from '2025-11-13T14:00:00' \
  --to '2025-11-13T15:00:00'
```

## Filtering

### By Source Category

```bash
sumo-query search --query '_sourceCategory=production/api error' \
  --from '2025-11-13T14:00:00' \
  --to '2025-11-13T15:00:00'
```

### Multiple Sources

```bash
sumo-query search --query '(_sourceCategory=prod/api OR _sourceCategory=prod/web) AND error' \
  --from '2025-11-13T14:00:00' \
  --to '2025-11-13T15:00:00'
```

### By Source Name

```bash
sumo-query search --query '_sourceName=server-01 error' \
  --from '2025-11-13T14:00:00' \
  --to '2025-11-13T15:00:00'
```

### Exclude Terms

```bash
sumo-query search --query 'error NOT "expected error"' \
  --from '2025-11-13T14:00:00' \
  --to '2025-11-13T15:00:00'
```

## Time-Based Analysis

### Timeline with Buckets

```bash
sumo-query search --query 'error | timeslice 5m | count by _timeslice' \
  --from '2025-11-13T14:00:00' \
  --to '2025-11-13T15:00:00'
```

### Hourly Aggregation

```bash
sumo-query search --query '* | timeslice 1h | count by _timeslice' \
  --from '2025-11-13T00:00:00' \
  --to '2025-11-13T23:59:59'
```

### Recent Activity

```bash
# Last hour (adjust --from time)
sumo-query search --query 'error' \
  --from "$(date -u -v-1H '+%Y-%m-%dT%H:%M:%S')" \
  --to "$(date -u '+%Y-%m-%dT%H:%M:%S')"
```

## Parsing and Fields

### Parse Specific Fields

```bash
sumo-query search --query '* | parse "user_id=* " as user_id | count by user_id' \
  --from '2025-11-13T14:00:00' \
  --to '2025-11-13T15:00:00'
```

### Extract Multiple Fields

```bash
sumo-query search --query '* | parse "status=* duration=*ms" as status, duration | fields status, duration' \
  --from '2025-11-13T14:00:00' \
  --to '2025-11-13T15:00:00'
```

### JSON Parsing

```bash
sumo-query search --query '* | json "user.id" as user_id | count by user_id' \
  --from '2025-11-13T14:00:00' \
  --to '2025-11-13T15:00:00'
```

## Aggregation

### Count by Field

```bash
sumo-query search --query '* | count by status_code' \
  --from '2025-11-13T14:00:00' \
  --to '2025-11-13T15:00:00'
```

### Group by Multiple Fields

```bash
sumo-query search --query '* | count by status_code, method' \
  --from '2025-11-13T14:00:00' \
  --to '2025-11-13T15:00:00'
```

### Sum Metrics

```bash
sumo-query search --query '* | parse "bytes=*" as bytes | sum(bytes) by host' \
  --from '2025-11-13T14:00:00' \
  --to '2025-11-13T15:00:00'
```

### Average Calculation

```bash
sumo-query search --query '* | parse "duration=*ms" as duration | avg(duration) by endpoint' \
  --from '2025-11-13T14:00:00' \
  --to '2025-11-13T15:00:00'
```

## Sorting and Limiting

### Top Results

```bash
sumo-query search --query '* | count by user_id | sort by _count desc | limit 10' \
  --from '2025-11-13T14:00:00' \
  --to '2025-11-13T15:00:00'
```

### Sort by Field

```bash
sumo-query search --query '* | parse "duration=*ms" as duration | sort by duration desc' \
  --from '2025-11-13T14:00:00' \
  --to '2025-11-13T15:00:00' \
  --limit 20
```

## Performance Monitoring

### Slow Requests

```bash
sumo-query search --query '* | parse "duration=*ms" as duration | where duration > 1000 | sort by duration desc' \
  --from '2025-11-13T14:00:00' \
  --to '2025-11-13T15:00:00' \
  --limit 50
```

### Error Rate

```bash
sumo-query search --query '* | if (status_code >= 500, 1, 0) as error | sum(error) / count as error_rate' \
  --from '2025-11-13T14:00:00' \
  --to '2025-11-13T15:00:00'
```

### Request Volume

```bash
sumo-query search --query '* | timeslice 1m | count by _timeslice | sort by _timeslice' \
  --from '2025-11-13T14:00:00' \
  --to '2025-11-13T15:00:00'
```

## Advanced Patterns

### Conditional Logic

```bash
sumo-query search --query '* | if (status_code >= 500, "error", if (status_code >= 400, "client_error", "success")) as category | count by category' \
  --from '2025-11-13T14:00:00' \
  --to '2025-11-13T15:00:00'
```

### Percentage Calculation

```bash
sumo-query search --query '* | count by status_code | total _count as total | ((_count / total) * 100) as percentage' \
  --from '2025-11-13T14:00:00' \
  --to '2025-11-13T15:00:00'
```

### Pattern Matching

```bash
sumo-query search --query '* | where message matches "*timeout*" OR message matches "*refused*"' \
  --from '2025-11-13T14:00:00' \
  --to '2025-11-13T15:00:00'
```

## Debugging

### Trace Request ID

```bash
REQUEST_ID="abc-123-def"
sumo-query search --query "_sourceCategory=* \"request_id=$REQUEST_ID\" | sort by _messagetime | fields _messagetime, _sourceCategory, message" \
  --from '2025-11-13T14:00:00' \
  --to '2025-11-13T15:00:00'
```

### Follow Transaction

```bash
TXN_ID="txn_xyz789"
sumo-query search --query "* \"transaction_id=$TXN_ID\" | sort by _messagetime | fields _messagetime, _sourceName, message" \
  --from '2025-11-13T14:00:00' \
  --to '2025-11-13T15:00:00'
```

### Stack Trace Analysis

```bash
sumo-query search --query 'error | where message matches "*Exception*" | fields _messagetime, message' \
  --from '2025-11-13T14:00:00' \
  --to '2025-11-13T15:00:00' \
  --limit 10
```

## Metadata Commands

### List All Collectors

```bash
sumo-query list-collectors --output collectors.json
```

### List All Sources

```bash
sumo-query list-sources --output sources.json
```

### List Sources for Specific Collector

```bash
# First, find collector ID
sumo-query list-collectors | jq '.collectors[] | select(.name | contains("marketplace"))'

# Then list its sources
sumo-query list-sources --collector-id 411318332 --output marketplace-sources.json
```

### Find Source Categories

```bash
# List all sources and extract unique categories
sumo-query list-sources | jq '.data[].sources[].category' | sort | uniq
```

## Saving Results

### Save to File

```bash
sumo-query search --query 'error' \
  --from '2025-11-13T14:00:00' \
  --to '2025-11-13T15:00:00' \
  --output results.json
```

### Process with jq

```bash
sumo-query search --query 'error' \
  --from '2025-11-13T14:00:00' \
  --to '2025-11-13T15:00:00' | \
  jq '.messages[].map.message'
```

## Tips

1. **Start narrow**: Use specific source categories to reduce query time
2. **Use aggregation**: Aggregate in Sumo Logic rather than fetching all raw data
3. **Test in UI first**: Validate complex queries in Sumo Logic UI before CLI
4. **Use --limit**: Cap results for exploratory queries
5. **Enable debug**: Use `--debug` to see polling progress
6. **Discover sources**: Use `list-sources` to find available log sources
7. **Default command**: `search` is the default - can omit it for brevity

## Resources

- **Sumo Logic Query Language**: https://help.sumologic.com/docs/search/
- **Search Operators**: https://help.sumologic.com/docs/search/search-query-language/search-operators/
- **Parse Operator**: https://help.sumologic.com/docs/search/search-query-language/parse-operators/
- **Collector Management API**: https://api.sumologic.com/docs/#tag/collectorManagement
