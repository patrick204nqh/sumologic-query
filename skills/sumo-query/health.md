---
name: health
description: Show Sumo Logic health dashboard — monitors in alert, health events, and collector status. Use when a user wants to check system health, see what's alerting, or get an overall status overview.
argument-hint: [optional: critical | warning | collectors | all]
---

# Health Dashboard

Check monitors, health events, and collector status to present a unified health dashboard. All results are saved to `.sumo-query/health-checks/` for review and trend comparison.

**Prerequisite:** Verify `sumo-query version` works. If not: `gem install sumologic-query`

**CLI reference:** For command flags, read `references/cli-reference.md`.

## Input

The user asked for: **$ARGUMENTS**

If `$ARGUMENTS` is empty, default to `all`.

Supported filters: `critical`, `warning`, `collectors`, `all` (default)

## Artifacts

Initialize the artifact directory at the start:

```bash
ARTIFACT_DIR=$(bash scripts/init-artifacts.sh health-checks)
```

For **every** `sumo-query` command, save output with `-o` and append to `queries.sh`. Use descriptive filenames: `monitors-critical.json`, `monitors-warning.json`, `monitors-missing-data.json`, `health-events.json`, `collectors.json`.

## Workflow

### Phase 1: Monitor Status

Run in parallel:

```bash
sumo-query list-monitors -s Critical -l 50 -o "$ARTIFACT_DIR/monitors-critical.json"
sumo-query list-monitors -s Warning -l 50 -o "$ARTIFACT_DIR/monitors-warning.json"
sumo-query list-monitors -s MissingData -l 50 -o "$ARTIFACT_DIR/monitors-missing-data.json"
```

If `$ARGUMENTS` is `critical`, skip Warning and MissingData.

### Phase 2: Health Events

```bash
sumo-query list-health-events -l 50 -o "$ARTIFACT_DIR/health-events.json"
```

### Phase 3: Collector Status

If `$ARGUMENTS` is `all` or `collectors`:

```bash
sumo-query list-collectors -o "$ARTIFACT_DIR/collectors.json"
```

### Phase 4: Present Dashboard

```
## Health Dashboard

### Overall Status: [HEALTHY | DEGRADED | CRITICAL]

- CRITICAL: Any monitor in Critical state or critical health events
- DEGRADED: Monitors in Warning/MissingData or non-critical health events
- HEALTHY: All Normal, no health events

---

### Monitors in Alert

#### Critical (N)
- [Monitor Name] — triggered since [time]

#### Warning (N)
- [Monitor Name] — triggered since [time]

#### Missing Data (N)
- [Monitor Name] — last data received [time]

### Recent Health Events (N)
- [Event type] — [resource] — [details] — [time]

### Collectors (N total)
- [N] alive, [N] dead/degraded
```

### Phase 5: Recommendations

- Critical monitors → suggest `/sumo-query:investigate <problem>`
- Missing data → suggest checking the specific collector/source
- Health events → suggest looking at related logs
- All healthy → confirm and suggest periodic checks

### Finalize Artifacts

Write **`$ARTIFACT_DIR/dashboard.md`** with the formatted dashboard.

Tell the user: `Artifacts saved to: $ARTIFACT_DIR/`

## Constraints

- **Read-only**: Never modify monitors, collectors, or configuration.
- **Safe defaults**: Always use `--limit`.
- **No interactive mode**: Never use the `-i` flag.
- **Always save artifacts** to `.sumo-query/health-checks/`.
- If a command fails, report the error and continue with other checks.
