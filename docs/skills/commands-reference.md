# sumo-query Commands Reference

This document provides a complete reference for all sumo-query CLI commands.

## Global Options

All commands support these global options:

| Option | Alias | Description |
|--------|-------|-------------|
| `--debug` | `-d` | Enable debug output for troubleshooting |
| `--output FILE` | `-o` | Write JSON output to file instead of stdout |

## Environment Variables

Required:
- `SUMO_ACCESS_ID` - Your Sumo Logic access ID
- `SUMO_ACCESS_KEY` - Your Sumo Logic access key

Optional:
- `SUMO_DEPLOYMENT` - Deployment region (default: `us2`). Options: `us1`, `us2`, `eu`, `au`, or full URL
- `SUMO_MAX_WORKERS` - Max parallel workers (default: 5)
- `SUMO_REQUEST_DELAY` - Delay between requests in seconds (default: 0.25)
- `SUMO_CONNECT_TIMEOUT` - Connection timeout in seconds (default: 10)
- `SUMO_READ_TIMEOUT` - Read timeout in seconds (default: 60)
- `SUMO_MAX_RETRIES` - Max retry attempts for failed requests (default: 3)

## Commands

### search

Search Sumo Logic logs with a query.

```bash
sumo-query search --query QUERY --from TIME --to TIME [options]
```

**Required Options:**
| Option | Alias | Description |
|--------|-------|-------------|
| `--query` | `-q` | Sumo Logic query string |
| `--from` | `-f` | Start time |
| `--to` | `-t` | End time |

**Optional:**
| Option | Alias | Description |
|--------|-------|-------------|
| `--time-zone` | `-z` | Time zone (default: UTC) |
| `--limit` | `-l` | Maximum messages to return |
| `--aggregate` | `-a` | Return aggregation records (for count/group by queries) |
| `--interactive` | `-i` | Launch FZF interactive browser |

**Time Formats:**
- `now` - Current time
- `-30s`, `-5m`, `-2h`, `-7d`, `-1w`, `-1M` - Relative time
- `1700000000` - Unix timestamp (seconds)
- `2024-01-15T14:00:00` - ISO 8601

**Examples:**
```bash
# Search errors in last hour
sumo-query search -q 'error' -f '-1h' -t 'now'

# Search with source filter
sumo-query search -q '_sourceCategory=prod/api error' -f '-30m' -t 'now'

# Aggregation query (count by source)
sumo-query search -q '* | count by _sourceCategory' -f '-1h' -t 'now' --aggregate

# Top 10 errors by host
sumo-query search -q 'error | count by _sourceHost | top 10' -f '-24h' -t 'now' -a
```

### discover-sources

Discover dynamic source names from actual log data.

```bash
sumo-query discover-sources [options]
```

**Options:**
| Option | Alias | Default | Description |
|--------|-------|---------|-------------|
| `--from` | `-f` | `-24h` | Start time |
| `--to` | `-t` | `now` | End time |
| `--time-zone` | `-z` | `UTC` | Time zone |
| `--filter` | | | Optional filter query |

**Examples:**
```bash
# Discover all sources from last 24 hours
sumo-query discover-sources

# Filter to ECS sources only
sumo-query discover-sources --filter '_sourceCategory=*ecs*'

# Discover CloudWatch sources from last 7 days
sumo-query discover-sources --from '-7d' --filter '_sourceCategory=*cloudwatch*'
```

### list-collectors

List all Sumo Logic collectors.

```bash
sumo-query list-collectors
```

**Output:** JSON with `total` count and `collectors` array.

### list-sources

List sources from collectors.

```bash
sumo-query list-sources [--collector-id ID]
```

**Options:**
| Option | Description |
|--------|-------------|
| `--collector-id` | Filter to specific collector |

### list-monitors

List all monitors (alerting rules).

```bash
sumo-query list-monitors [--limit N]
```

**Options:**
| Option | Alias | Default | Description |
|--------|-------|---------|-------------|
| `--limit` | `-l` | 100 | Maximum monitors to return |

### get-monitor

Get detailed information about a specific monitor.

```bash
sumo-query get-monitor --monitor-id ID
```

### list-folders

List folders in the content library.

```bash
sumo-query list-folders [options]
```

**Options:**
| Option | Default | Description |
|--------|---------|-------------|
| `--folder-id` | personal | Folder ID to list |
| `--tree` | false | Fetch recursive tree structure |
| `--depth` | 3 | Maximum tree depth |

**Examples:**
```bash
# List personal folder contents
sumo-query list-folders

# Get folder tree
sumo-query list-folders --tree --depth 2

# List specific folder
sumo-query list-folders --folder-id 0000000000123456
```

### list-dashboards

List all dashboards.

```bash
sumo-query list-dashboards [--limit N]
```

**Options:**
| Option | Alias | Default | Description |
|--------|-------|---------|-------------|
| `--limit` | `-l` | 100 | Maximum dashboards to return |

### get-dashboard

Get detailed information about a specific dashboard.

```bash
sumo-query get-dashboard --dashboard-id ID
```

### version

Display version information.

```bash
sumo-query version
sumo-query -v
sumo-query --version
```

## Output Format

All commands output JSON. Common patterns:

**List commands:**
```json
{
  "total": 42,
  "items": [...]
}
```

**Search commands:**
```json
{
  "query": "error",
  "from": "2024-01-15T00:00:00Z",
  "to": "2024-01-15T01:00:00Z",
  "message_count": 150,
  "messages": [...]
}
```

**Aggregation search:**
```json
{
  "query": "* | count by _sourceCategory",
  "record_count": 25,
  "records": [...]
}
```
