---
name: discover
description: Map your Sumo Logic infrastructure — collectors, sources, dashboards, fields, and apps. Use when a user wants to understand what's deployed, explore their environment, or get an infrastructure overview.
argument-hint: [scope: all | collectors | sources | dashboards | fields | apps]
---

# Infrastructure Discovery

Map the user's Sumo Logic environment to give a clear picture of what's deployed. All results are saved to `.sumo-query/discoveries/` for review.

**Prerequisite:** Verify `sumo-query version` works. If not: `gem install sumologic-query`

**CLI reference:** For command flags, read `references/cli-reference.md`.

## Input

The user asked to discover: **$ARGUMENTS**

If `$ARGUMENTS` is empty, default to `all`.

Supported scopes: `all` (default), `collectors`, `sources`, `dashboards`, `fields`, `apps`

## Artifacts

Initialize the artifact directory at the start:

```bash
SCOPE=$(echo '$ARGUMENTS' | tr '[:upper:]' '[:lower:]'); SCOPE=${SCOPE:-all}
ARTIFACT_DIR=$(bash scripts/init-artifacts.sh discoveries "$SCOPE")
```

For **every** `sumo-query` command, save output with `-o` and append to `queries.sh`. Use descriptive filenames: `collectors.json`, `sources.json`, `dynamic-sources.json`, `dashboards.json`, `folders.json`, `fields.json`, `fields-builtin.json`, `apps.json`.

## Workflow

### Scope: collectors

```bash
sumo-query list-collectors -o "$ARTIFACT_DIR/collectors.json"
```

Filter by service: `sumo-query list-collectors -q "<keyword>" -l 20`

For each collector (limit first 10), list its sources:
```bash
sumo-query list-sources --collector-id <id> -o "$ARTIFACT_DIR/sources-<id>.json"
```

### Scope: sources

```bash
sumo-query list-sources -o "$ARTIFACT_DIR/sources.json"
sumo-query discover-source-metadata -f -7d -t now -o "$ARTIFACT_DIR/dynamic-sources.json"
```

Filter: `sumo-query list-sources --collector "<keyword>" --name "<keyword>" -l 30`

### Scope: dashboards

Run in parallel:
```bash
sumo-query list-dashboards -l 100 -o "$ARTIFACT_DIR/dashboards.json"
sumo-query list-folders --tree --depth 2 -o "$ARTIFACT_DIR/folders.json"
```

### Scope: fields

Run in parallel:
```bash
sumo-query list-fields -o "$ARTIFACT_DIR/fields.json"
sumo-query list-fields --builtin -o "$ARTIFACT_DIR/fields-builtin.json"
```

### Scope: apps

```bash
sumo-query list-apps -o "$ARTIFACT_DIR/apps.json"
```

### Scope: all

Run all scopes above. Start with parallel-safe commands, then sequential ones.

## Output

Present as an infrastructure map:

```
## Infrastructure Map

### Collectors (N total)
| Name | ID | Type | Status |

### Sources (N total)
| Name | Collector | Category | Type |

### Dynamic Sources (from log metadata)
| Source Category | Source Name | Source Host | Seen In |

### Dashboards (N total)
| Name | ID | Description |

### Content Folders
<tree view>

### Fields
**Custom (N):** field1, field2, ...
**Built-in (N):** _sourceCategory, _sourceHost, ...

### Apps (N available)
| Name | Description |
```

After the map, provide a brief summary with totals and suggestions (e.g., "run `/sumo-query:health` to check monitor status").

### Finalize Artifacts

Write **`$ARTIFACT_DIR/infrastructure-map.md`** with the formatted map.

Tell the user: `Artifacts saved to: $ARTIFACT_DIR/`

## Constraints

- **Read-only**: Never create, modify, or delete resources.
- **Safe defaults**: Always use `--limit` on commands that support it.
- **No interactive mode**: Never use the `-i` flag.
- **Always save artifacts** to `.sumo-query/discoveries/`.
- **Throttle drilldown**: Only fetch sources for the first 10 collectors to avoid rate limits.
- If a command fails, report the error and continue with other discovery commands.
