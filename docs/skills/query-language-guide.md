# Sumo Logic Query Language Guide

This guide covers the essential Sumo Logic query syntax for use with sumo-query.

## Basic Search

### Keyword Search

```
error
"connection refused"
exception AND timeout
error OR warning
error NOT debug
```

### Metadata Filters

Built-in metadata fields start with underscore:

| Field | Description |
|-------|-------------|
| `_sourceCategory` | Source category (e.g., `prod/api/logs`) |
| `_sourceName` | Source name |
| `_sourceHost` | Host that sent the log |
| `_collector` | Collector name |
| `_source` | Full source identifier |
| `_messageTime` | Timestamp of the message |
| `_raw` | Raw log message |

**Examples:**
```
_sourceCategory=prod/api
_sourceCategory=*ecs*
_sourceHost=web-server-01
_sourceCategory=prod/* AND error
```

### Wildcards

- `*` matches any characters
- `?` matches single character

```
_sourceCategory=prod/*
error*
status=40?
```

## Operators

### Parse Operators

Extract fields from unstructured logs:

```
| parse "user=* action=*" as user, action
| parse regex "status=(?<status>\d+)"
| json field=_raw "user.name" as username
| csv _raw extract timestamp, level, message
```

### Filter Operators

```
| where status >= 400
| where user matches "*admin*"
| where !isBlank(error_code)
| where _messageTime > now() - 1h
```

### Aggregation Operators

Use with `--aggregate` flag:

```
| count
| count by _sourceCategory
| count by _sourceHost, status
| sum(bytes) by endpoint
| avg(response_time) by service
| min(latency), max(latency), avg(latency) by endpoint
| count_distinct(user_id) by region
```

### Sorting and Limiting

```
| sort by _count desc
| top 10 _sourceHost by _count
| limit 100
```

### Time Operations

```
| timeslice 5m
| timeslice 1h
| count by _timeslice
```

## Common Query Patterns

### Error Analysis

```bash
# Count errors by source
sumo-query search -q 'error | count by _sourceCategory' -f '-1h' -t 'now' -a

# Top error messages
sumo-query search -q 'error | parse "Error: *" as error_msg | count by error_msg | top 10' -f '-1h' -t 'now' -a

# Error rate over time
sumo-query search -q 'error | timeslice 5m | count by _timeslice' -f '-1h' -t 'now' -a
```

### HTTP Status Codes

```bash
# Count by status code
sumo-query search -q '| parse "status=*" as status | count by status' -f '-1h' -t 'now' -a

# 5xx errors only
sumo-query search -q '| parse "status=*" as status | where status >= 500' -f '-1h' -t 'now'

# Status distribution
sumo-query search -q '| parse "status=*" as status | count by status | sort by _count desc' -f '-1h' -t 'now' -a
```

### Performance Analysis

```bash
# Average response time by endpoint
sumo-query search -q '| parse "duration=*ms" as duration | avg(duration) by endpoint' -f '-1h' -t 'now' -a

# Slow requests (>1s)
sumo-query search -q '| parse "duration=*ms" as duration | where duration > 1000' -f '-1h' -t 'now'

# P95 latency
sumo-query search -q '| parse "latency=*" as latency | pct(latency, 95) by service' -f '-1h' -t 'now' -a
```

### User Activity

```bash
# Active users
sumo-query search -q '| parse "user_id=*" as user | count_distinct(user) by _timeslice 1h' -f '-24h' -t 'now' -a

# Actions by user
sumo-query search -q '| parse "user=* action=*" as user, action | count by user, action | top 20' -f '-1h' -t 'now' -a
```

### Source Discovery

```bash
# All unique source categories
sumo-query search -q '* | count by _sourceCategory' -f '-1h' -t 'now' -a

# Sources with most logs
sumo-query search -q '* | count by _sourceName | top 20' -f '-1h' -t 'now' -a

# Dynamic source discovery (specialized command)
sumo-query discover-sources --from '-24h'
```

## JSON Logs

For JSON-formatted logs:

```
| json field=_raw "level"
| json field=_raw "request.method" as method
| json field=_raw "response.status" as status
| json auto
```

**Example:**
```bash
sumo-query search -q '| json field=_raw "level" | where level="error" | count by level' -f '-1h' -t 'now' -a
```

## Tips for sumo-query

1. **Use `--aggregate` for count/group by queries** - Returns structured records instead of raw messages

2. **Start broad, then narrow** - Begin with a wide time range and simple query, then add filters

3. **Use relative times** - `-1h`, `-30m`, `-7d` are easier than ISO timestamps

4. **Check message count first** - Large result sets may take time; use `--limit` to cap results

5. **Save results to file** - Use `-o results.json` for large outputs

6. **Debug mode** - Use `-d` to see API calls and timing information
