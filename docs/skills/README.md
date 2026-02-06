# sumo-query Claude Skill

This directory contains documentation for using sumo-query as a Claude Code skill.

## Overview

sumo-query is a command-line tool for querying Sumo Logic logs and metadata. It provides read-only access to:

- **Log Search** - Query logs with full Sumo Logic query language support
- **Aggregation Queries** - Count, sum, average, group by operations
- **Metadata** - Collectors, sources, monitors, folders, dashboards
- **Dynamic Source Discovery** - Find sources from actual log data

## Quick Start

```bash
# Search for errors in the last hour
sumo-query search -q 'error' -f '-1h' -t 'now'

# Count errors by source
sumo-query search -q 'error | count by _sourceCategory' -f '-1h' -t 'now' --aggregate

# List monitors
sumo-query list-monitors

# Discover active sources
sumo-query discover-sources --from '-24h'
```

## Documentation

| Document | Description |
|----------|-------------|
| [commands-reference.md](commands-reference.md) | Complete CLI command reference |
| [query-language-guide.md](query-language-guide.md) | Sumo Logic query syntax |
| [investigation-playbooks.md](investigation-playbooks.md) | Common investigation patterns |
| [result-interpretation.md](result-interpretation.md) | Understanding query output |

## Environment Setup

Required environment variables:
```bash
export SUMO_ACCESS_ID='your_access_id'
export SUMO_ACCESS_KEY='your_access_key'
export SUMO_DEPLOYMENT='us2'  # us1, us2, eu, au
```

## Common Tasks

### Find Errors
```bash
# Recent errors
sumo-query search -q 'error OR exception' -f '-1h' -t 'now'

# Errors by source
sumo-query search -q 'error | count by _sourceCategory' -f '-1h' -t 'now' -a
```

### Analyze Trends
```bash
# Error rate over time
sumo-query search -q 'error | timeslice 5m | count by _timeslice' -f '-1h' -t 'now' -a
```

### Check Infrastructure
```bash
# List collectors
sumo-query list-collectors

# List all sources
sumo-query list-sources

# Check monitors/alerts
sumo-query list-monitors
```

### Save Results
```bash
# Save to file
sumo-query search -q 'error' -f '-1h' -t 'now' -o errors.json
```

## Output Format

All commands output JSON. Use `jq` for processing:

```bash
# Get message count
sumo-query search -q 'error' -f '-1h' -t 'now' | jq '.message_count'

# Extract raw messages
sumo-query search -q 'error' -f '-1h' -t 'now' | jq '.messages[].map._raw'
```
