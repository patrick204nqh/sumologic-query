# Sumo Logic CLI Reference

## CLI Commands

### Search

```bash
# Basic search
sumo-query search -q '_sourceCategory=prod | where status >= 400' -f -1h -t now

# With limit
sumo-query search -q 'error' -f -1h -t now -l 50

# Aggregation mode (for count/group queries)
sumo-query search -q '_sourceCategory=prod | count by _sourceHost' -f -1h -t now -a

# Custom timezone
sumo-query search -q 'error' -f -1h -t now -z America/New_York
```

#### Search Flags

| Flag | Long          | Required | Description                |
| ---- | ------------- | -------- | -------------------------- |
| `-q` | `--query`     | Yes      | Sumo Logic query string    |
| `-f` | `--from`      | Yes      | Start time                 |
| `-t` | `--to`        | Yes      | End time                   |
| `-l` | `--limit`     | No       | Max results to return      |
| `-a` | `--aggregate` | No       | Return aggregation records |
| `-z` | `--time-zone` | No       | Timezone (default: UTC)    |
| `-d` | `--debug`     | No       | Debug output               |
| `-o` | `--output`    | No       | Write JSON to file         |

### Monitors

```bash
sumo-query list-monitors
sumo-query list-monitors -s Critical
sumo-query list-monitors -s Warning
sumo-query list-monitors -s MissingData
sumo-query list-monitors -s AllTriggered
sumo-query list-monitors -q "payment"
sumo-query get-monitor --monitor-id 00000000001A2B3C
```

#### list-monitors Flags

| Flag | Long       | Required | Description                                                            |
| ---- | ---------- | -------- | ---------------------------------------------------------------------- |
| `-s` | `--status` | No       | Filter: Normal, Critical, Warning, MissingData, Disabled, AllTriggered |
| `-q` | `--query`  | No       | Search name/description                                                |
| `-l` | `--limit`  | No       | Max results (default: 100)                                             |

### Health Events

```bash
sumo-query list-health-events
sumo-query list-health-events -l 50
```

### Collectors & Sources

```bash
sumo-query list-collectors
sumo-query list-collectors -q "my-service" -l 20
sumo-query list-sources --collector-id 123456789
sumo-query list-sources
sumo-query list-sources --collector "my-service" --name "nginx" -l 20
sumo-query list-sources --category "production"
sumo-query discover-source-metadata
sumo-query discover-source-metadata --filter '_sourceCategory=*ecs*'
sumo-query discover-source-metadata -f -7d -t now
sumo-query discover-source-metadata -k "nginx" -l 20
```

#### list-collectors Flags

| Flag | Long      | Required | Description                                   |
| ---- | --------- | -------- | --------------------------------------------- |
| `-q` | `--query` | No       | Filter by name or category (case-insensitive) |
| `-l` | `--limit` | No       | Max results to return                         |

#### list-sources Flags

| Flag | Long             | Required | Description                                  |
| ---- | ---------------- | -------- | -------------------------------------------- |
|      | `--collector-id` | No       | Collector ID to list sources for             |
|      | `--collector`    | No       | Filter by collector name (case-insensitive)  |
| `-n` | `--name`         | No       | Filter by source name (case-insensitive)     |
|      | `--category`     | No       | Filter by source category (case-insensitive) |
| `-l` | `--limit`        | No       | Max total sources to return                  |

#### discover-source-metadata Flags

| Flag | Long          | Required | Description                                             |
| ---- | ------------- | -------- | ------------------------------------------------------- |
| `-f` | `--from`      | No       | Start time (default: -24h)                              |
| `-t` | `--to`        | No       | End time (default: now)                                 |
| `-z` | `--time-zone` | No       | Timezone (default: UTC)                                 |
|      | `--filter`    | No       | Sumo Logic query filter (e.g., `_sourceCategory=*ecs*`) |
| `-k` | `--keyword`   | No       | Filter results by keyword (matches name or category)    |
| `-l` | `--limit`     | No       | Max sources to return                                   |

### Dashboards & Folders

```bash
sumo-query list-dashboards -l 50
sumo-query get-dashboard --dashboard-id 8mXYZ123abc
sumo-query list-folders
sumo-query list-folders --folder-id 00000000001A2B3C
sumo-query list-folders --tree --depth 5
```

### Fields

```bash
sumo-query list-fields
sumo-query list-fields --builtin
```

### Content Library

```bash
sumo-query get-content -p "/Library/Users/me/My Saved Search"
sumo-query export-content --content-id 00000000001A2B3C
```

### Apps & Lookup Tables

```bash
sumo-query list-apps
sumo-query get-lookup --lookup-id 00000000001A2B3C
```

---

## Time Format Reference

### Relative Times

| Format   | Meaning               |
| -------- | --------------------- |
| `-15m`   | 15 minutes ago        |
| `-1h`    | 1 hour ago            |
| `-1h30m` | 1 hour 30 minutes ago |
| `-6h`    | 6 hours ago           |
| `-1d`    | 1 day ago             |
| `-2d3h`  | 2 days 3 hours ago    |
| `-7d`    | 7 days ago            |
| `-1w`    | 1 week ago            |
| `-1M`    | 1 month ago           |
| `now`    | Current time          |

Compound expressions (e.g., `-1h30m`, `-2d3h15m`) are supported.

### Absolute Times

| Format         | Example               |
| -------------- | --------------------- |
| ISO 8601       | `2025-01-15T14:00:00` |
| Unix timestamp | `1700000000`          |

### Timezones

| Value              | Description             |
| ------------------ | ----------------------- |
| `UTC`              | Default                 |
| `EST`              | US Eastern              |
| `AEST`             | Australian Eastern      |
| `America/New_York` | IANA US Eastern         |
| `Australia/Sydney` | IANA Australian Eastern |
| `+05:30`           | UTC offset format       |

---

## Sumo Logic Query Syntax

### Basic Structure

```
<scope> | <operator1> | <operator2> | ...
```

### Scope

```
_sourceCategory=prod/api
_sourceHost=web-server-*
_source=my-log-source
_collector=my-collector
```

Combine with `AND`, `OR`, `NOT`:

```
_sourceCategory=prod AND error
(_sourceCategory=api OR _sourceCategory=web) AND status=500
```

### Keywords

```
error
"connection refused"
error OR warning
error NOT "expected error"
```

### Parse Operators

```
| parse "status=* method=* path=*" as status, method, path
| parse regex "(?<ip>\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})"
| json "response.status" as status
| json auto
| csv _raw extract 1 as ip, 2 as method, 3 as url
| keyvalue infer "=" ","
```

### Filter Operators

```
| where status >= 400
| where method in ("GET", "POST")
| where url matches "*api/v2*"
| where !isNull(response_time)
```

Comparison: `=`, `!=`, `>`, `>=`, `<`, `<=`, `in`, `matches`

### Aggregation

```
| count by _sourceCategory
| avg(response_time) by endpoint
| sum(bytes) by _sourceHost
| pct(response_time, 95) as p95 by endpoint
| min(latency) as min_lat, max(latency) as max_lat by service
| count_distinct(user)
| first(_raw) by _sourceHost
```

### Time Bucketing

```
| timeslice 1m | count by _timeslice
| timeslice 5m | avg(response_time) by _timeslice
```

### Sort and Limit

```
| sort by _count desc
| top 10 _sourceCategory by _count
| limit 20
```

### Conditional

```
| if(status >= 400, "error", "ok") as status_class
| if(isNull(user), "anonymous", user) as display_user
```

### Dedup

```
| dedup by _sourceHost
| dedup 3 by user
```

### String / Numeric Functions

```
| toLowerCase(field) | toUpperCase(field) | substring(field, 0, 10)
| concat(field1, " - ", field2) as combined | length(field) as len
| num(status) as status_num | round(value, 2)
```

---

## Common Query Patterns

**Error rate:**
```
_sourceCategory=prod
| if(status >= 400, 1, 0) as is_error
| avg(is_error) as error_rate by _sourceHost
| sort by error_rate desc
```

**Top errors:**
```
_sourceCategory=prod error
| parse "error: *" as error_msg
| count by error_msg | sort by _count desc | limit 10
```

**Latency percentiles:**
```
_sourceCategory=prod/api
| json "response_time" as rt
| pct(rt, 50) as p50, pct(rt, 95) as p95, pct(rt, 99) as p99 by endpoint
```

**Traffic over time:**
```
_sourceCategory=prod | timeslice 5m | count by _timeslice
```

**Status code breakdown:**
```
_sourceCategory=prod
| parse "status=*" as status | count by status | sort by _count desc
```

**Slow requests:**
```
_sourceCategory=prod/api
| json "response_time" as rt | where rt > 3000 | sort by rt desc | limit 20
```
