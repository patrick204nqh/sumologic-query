# Result Interpretation Guide

How to interpret and work with sumo-query output.

## Output Structure

### Search Results (Messages)

```json
{
  "query": "error",
  "from": "2024-01-15T00:00:00Z",
  "to": "2024-01-15T01:00:00Z",
  "from_original": "-1h",
  "to_original": "now",
  "time_zone": "UTC",
  "message_count": 150,
  "messages": [
    {
      "map": {
        "_messagetime": "1705276800000",
        "_raw": "2024-01-15T00:00:00Z ERROR Connection timeout",
        "_sourceCategory": "prod/api/logs",
        "_sourceHost": "web-server-01",
        "_sourceName": "/var/log/app.log"
      }
    }
  ]
}
```

**Key Fields:**
- `message_count`: Total messages returned
- `messages[].map._raw`: The actual log message
- `messages[].map._messagetime`: Unix timestamp in milliseconds
- `messages[].map._sourceCategory`: Source category
- `messages[].map._sourceHost`: Originating host

### Aggregation Results (Records)

```json
{
  "query": "* | count by _sourceCategory",
  "record_count": 25,
  "records": [
    {
      "map": {
        "_sourcecategory": "prod/api/logs",
        "_count": "15234"
      }
    },
    {
      "map": {
        "_sourcecategory": "prod/worker/logs",
        "_count": "8921"
      }
    }
  ]
}
```

**Key Fields:**
- `record_count`: Number of aggregation groups
- `records[].map`: Key-value pairs for each group
- `_count`: Built-in count field (note: values are strings)

## Common Output Patterns

### Count by Category

Query: `* | count by _sourceCategory`

```json
{
  "records": [
    { "map": { "_sourcecategory": "prod/api", "_count": "15000" } },
    { "map": { "_sourcecategory": "prod/web", "_count": "8000" } },
    { "map": { "_sourcecategory": "prod/db", "_count": "3000" } }
  ]
}
```

**Interpretation:**
- Most active source is `prod/api` with 15,000 messages
- Total log volume across sources
- Useful for identifying verbose or silent sources

### Timeslice Analysis

Query: `error | timeslice 5m | count by _timeslice`

```json
{
  "records": [
    { "map": { "_timeslice": "1705276800000", "_count": "45" } },
    { "map": { "_timeslice": "1705277100000", "_count": "120" } },
    { "map": { "_timeslice": "1705277400000", "_count": "85" } }
  ]
}
```

**Interpretation:**
- `_timeslice` is Unix timestamp in milliseconds
- Spike at 1705277100000 (2.67x increase) - investigate this window
- Convert timestamp: `new Date(1705277100000)` = 2024-01-14T21:05:00.000Z

### Error Distribution

Query: `| parse "status=*" as status | count by status`

```json
{
  "records": [
    { "map": { "status": "200", "_count": "45000" } },
    { "map": { "status": "500", "_count": "150" } },
    { "map": { "status": "503", "_count": "75" } },
    { "map": { "status": "404", "_count": "500" } }
  ]
}
```

**Interpretation:**
- 99.5% success rate (200s)
- 225 server errors (500 + 503) = 0.5% error rate
- 503s may indicate capacity issues
- 404s often normal (missing resources)

## Working with Results

### Converting Timestamps

The `_messagetime` and `_timeslice` fields are Unix timestamps in milliseconds:

```python
# Python
from datetime import datetime
ts = 1705276800000
dt = datetime.fromtimestamp(ts / 1000)
# 2024-01-14 21:00:00
```

```ruby
# Ruby
ts = 1705276800000
Time.at(ts / 1000)
# 2024-01-14 21:00:00 UTC
```

```javascript
// JavaScript
const ts = 1705276800000;
new Date(ts);
// Sun Jan 14 2024 21:00:00
```

### Processing with jq

```bash
# Extract just the raw messages
sumo-query search -q 'error' -f '-1h' -t 'now' | jq '.messages[].map._raw'

# Get counts as numbers
sumo-query search -q '* | count by _sourceCategory' -f '-1h' -t 'now' -a | jq '.records[].map | {source: ._sourcecategory, count: (._count | tonumber)}'

# Sort by count
sumo-query search -q '* | count by _sourceCategory' -f '-1h' -t 'now' -a | jq '[.records[].map | {source: ._sourcecategory, count: (._count | tonumber)}] | sort_by(.count) | reverse'

# Filter results
sumo-query search -q 'error' -f '-1h' -t 'now' | jq '.messages[] | select(.map._sourceCategory | contains("api"))'
```

### Aggregating Locally

```bash
# Total error count
sumo-query search -q 'error | count by _sourceCategory' -f '-1h' -t 'now' -a | jq '[.records[].map._count | tonumber] | add'

# Average per source
sumo-query search -q 'error | count by _sourceCategory' -f '-1h' -t 'now' -a | jq '([.records[].map._count | tonumber] | add) / .record_count'
```

## Interpreting Common Scenarios

### Healthy vs Unhealthy Patterns

**Healthy:**
- Consistent message counts over time
- Low error rates (<1%)
- Latency within expected bounds
- All sources reporting

**Unhealthy:**
- Sudden spikes or drops in message volume
- Error rate increase
- Latency spikes
- Silent sources (may indicate service failure)

### Red Flags

| Pattern | Possible Issue |
|---------|---------------|
| Zero messages | Query too narrow, source down, or ingestion issue |
| Sudden volume spike | Attack, misconfiguration, or incident |
| Volume drop to zero | Service failure or network issue |
| 5xx spike | Application error, dependency failure |
| Timeout errors | Network, database, or external service issues |
| OOM messages | Memory leak or undersized containers |
| Connection refused | Service down or network partition |

### Result Limits

- **Empty results**: Check query syntax, time range, source category
- **Too many results**: Add filters, reduce time range, use `--limit`
- **Slow queries**: Narrow time range, add source filters, use aggregation

## Tips for Analysis

1. **Start with aggregations** - Get overview before diving into raw logs
2. **Use timeslice** - Identify when issues started
3. **Compare time ranges** - "Last hour" vs "same hour yesterday"
4. **Check multiple sources** - Issues may span services
5. **Save significant results** - Use `-o` to preserve investigation data
6. **Note timestamps** - Convert to human-readable for reports
