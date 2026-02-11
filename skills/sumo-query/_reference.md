---
description: Sumo Logic CLI reference — commands, query syntax, time formats
argument-hint: <topic> (commands | query-syntax | time | all)
---

You are a Sumo Logic CLI reference assistant. The user has access to `sumo-query`, a CLI tool for querying Sumo Logic.

## Prerequisite

Verify the CLI is installed:

```bash
sumo-query version
```

If the command fails, tell the user to install it: `gem install sumologic-query`

## Requested Topic

The user asked about: **$ARGUMENTS**

If `$ARGUMENTS` is empty, show a brief table of contents and ask which topic they want:
- `commands` — All CLI commands and flags
- `query-syntax` — Sumo Logic query language reference
- `time` — Time format and timezone reference
- `all` — Everything

Otherwise, show the relevant section(s) below.

---

# CLI Commands Reference

## Search

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

### Search Flags
| Flag | Long | Required | Description |
|------|------|----------|-------------|
| `-q` | `--query` | Yes | Sumo Logic query string |
| `-f` | `--from` | Yes | Start time |
| `-t` | `--to` | Yes | End time |
| `-l` | `--limit` | No | Max results to return |
| `-a` | `--aggregate` | No | Return aggregation records |
| `-z` | `--time-zone` | No | Timezone (default: UTC) |
| `-d` | `--debug` | No | Debug output |
| `-o` | `--output` | No | Write JSON to file |

## Monitors

```bash
# List all monitors
sumo-query list-monitors

# Filter by status
sumo-query list-monitors -s Critical
sumo-query list-monitors -s Warning
sumo-query list-monitors -s MissingData
sumo-query list-monitors -s AllTriggered

# Search by name
sumo-query list-monitors -q "payment"

# Get specific monitor details
sumo-query get-monitor --monitor-id 00000000001A2B3C
```

### list-monitors Flags
| Flag | Long | Required | Description |
|------|------|----------|-------------|
| `-s` | `--status` | No | Filter: Normal, Critical, Warning, MissingData, Disabled, AllTriggered |
| `-q` | `--query` | No | Search name/description |
| `-l` | `--limit` | No | Max results (default: 100) |

## Health Events

```bash
sumo-query list-health-events
sumo-query list-health-events -l 50
```

## Collectors & Sources

```bash
# List all collectors
sumo-query list-collectors

# List sources for a specific collector
sumo-query list-sources --collector-id 123456789

# List all sources across all collectors
sumo-query list-sources

# Discover dynamic source metadata from logs
sumo-query discover-source-metadata
sumo-query discover-source-metadata --filter '_sourceCategory=*ecs*'
sumo-query discover-source-metadata -f -7d -t now
```

## Dashboards & Folders

```bash
# List dashboards
sumo-query list-dashboards -l 50

# Get dashboard details
sumo-query get-dashboard --dashboard-id 8mXYZ123abc

# List personal folder
sumo-query list-folders

# List specific folder
sumo-query list-folders --folder-id 00000000001A2B3C

# Recursive tree view
sumo-query list-folders --tree --depth 5
```

## Fields

```bash
# Custom fields
sumo-query list-fields

# Built-in fields
sumo-query list-fields --builtin
```

## Content Library

```bash
# Look up content by path
sumo-query get-content -p "/Library/Users/me/My Saved Search"

# Export content as JSON
sumo-query export-content --content-id 00000000001A2B3C
```

## Apps & Lookup Tables

```bash
# List available apps
sumo-query list-apps

# Get lookup table details
sumo-query get-lookup --lookup-id 00000000001A2B3C
```

---

# Time Format Reference

## Relative Times
| Format | Meaning |
|--------|---------|
| `-15m` | 15 minutes ago |
| `-1h` | 1 hour ago |
| `-6h` | 6 hours ago |
| `-1d` | 1 day ago |
| `-7d` | 7 days ago |
| `-1w` | 1 week ago |
| `-1M` | 1 month ago |
| `now` | Current time |

## Absolute Times
| Format | Example |
|--------|---------|
| ISO 8601 | `2025-01-15T14:00:00` |
| Unix timestamp | `1700000000` |

## Timezones
| Value | Description |
|-------|-------------|
| `UTC` | Default |
| `EST` | US Eastern |
| `AEST` | Australian Eastern |
| `America/New_York` | IANA US Eastern |
| `Australia/Sydney` | IANA Australian Eastern |
| `+05:30` | UTC offset format |

---

# Sumo Logic Query Syntax Reference

## Basic Structure

```
<scope> | <operator1> | <operator2> | ...
```

The scope selects which logs to search. Operators filter, parse, and transform.

## Scope (Where Clause)

```
_sourceCategory=prod/api
_sourceHost=web-server-*
_source=my-log-source
_collector=my-collector
```

Combine with `AND`, `OR`, `NOT`:
```
_sourceCategory=prod AND error
_sourceCategory=prod NOT "health check"
(_sourceCategory=api OR _sourceCategory=web) AND status=500
```

## Keyword Search

```
error
"connection refused"
error OR warning
error NOT "expected error"
```

## Parse Operators

### parse (anchor-based)
```
| parse "status=* method=* path=*" as status, method, path
```

### parse regex
```
| parse regex "(?<ip>\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})"
| parse regex "status=(?<status>\d+)"
```

### json
```
| json "response.status" as status
| json "user.name" as username
| json auto
```

### csv / keyvalue / xml
```
| csv _raw extract 1 as ip, 2 as method, 3 as url
| keyvalue infer "=" ","
| xml "/root/element" as value
```

## Filter Operators

### where
```
| where status >= 400
| where status = 200
| where !(user = "bot")
| where method in ("GET", "POST")
| where isNull(error_code)
| where !isNull(response_time)
| where response_time > 5000
```

### Comparison operators
`=`, `!=`, `>`, `>=`, `<`, `<=`, `in`, `matches`

### String matching
```
| where method matches "GET*"
| where url matches "*api/v2*"
| where toLowerCase(message) matches "*error*"
```

## Aggregation Operators

### count
```
| count                          # total count
| count by _sourceCategory       # count per category
| count by status, method        # count by multiple fields
| count as request_count by path # named count
```

### Statistical
```
| avg(response_time) by endpoint
| sum(bytes) by _sourceHost
| min(latency) as min_latency, max(latency) as max_latency by service
| pct(response_time, 95) as p95 by endpoint
| pct(response_time, 50) as p50, pct(response_time, 99) as p99
```

### first / last
```
| first(_raw) by _sourceHost
| last(message) by user
```

## Sort and Limit

```
| sort by _count desc
| sort by response_time asc
| limit 20
| top 10 _sourceCategory by _count
```

## Time Operations

### timeslice
```
| timeslice 1m                    # group by 1-minute buckets
| timeslice 5m                    # 5-minute buckets
| timeslice 1h                    # hourly buckets
| count by _timeslice             # count per time bucket
```

### formatDate
```
| formatDate(_messageTime, "yyyy-MM-dd HH:mm:ss") as timestamp
```

## String Functions

```
| toLowerCase(field)
| toUpperCase(field)
| substring(field, 0, 10)
| concat(field1, " - ", field2) as combined
| replace(field, "old", "new") as replaced
| length(field) as field_length
| trim(field)
```

## Numeric Functions

```
| num(status) as status_num
| abs(value)
| ceil(value)
| floor(value)
| round(value, 2)
```

## Conditional

```
| if(status >= 400, "error", "ok") as status_class
| if(isNull(user), "anonymous", user) as display_user
```

## Dedup

```
| dedup by _sourceHost           # keep first occurrence per host
| dedup 3 by user                # keep up to 3 per user
```

## Transpose

```
| count by status | transpose row _count column status
```

---

# Common Query Patterns

## Error Rate

```
_sourceCategory=prod
| if(status >= 400, 1, 0) as is_error
| avg(is_error) as error_rate by _sourceHost
| sort by error_rate desc
```

## Top Errors

```
_sourceCategory=prod error
| parse "error: *" as error_msg
| count by error_msg
| sort by _count desc
| limit 10
```

## Latency Percentiles

```
_sourceCategory=prod/api
| json "response_time" as rt
| pct(rt, 50) as p50, pct(rt, 95) as p95, pct(rt, 99) as p99 by endpoint
| sort by p99 desc
```

## Traffic Over Time

```
_sourceCategory=prod
| timeslice 5m
| count by _timeslice
```

## Status Code Breakdown

```
_sourceCategory=prod
| parse "status=*" as status
| count by status
| sort by _count desc
```

## Slow Requests

```
_sourceCategory=prod/api
| json "response_time" as rt
| where rt > 3000
| sort by rt desc
| limit 20
```

## Constraints

- This is a **read-only** reference. Do not modify any files unless the user explicitly asks.
- Always verify `sumo-query` is accessible before running commands.
- Use `--limit` on search commands to avoid excessive output.
