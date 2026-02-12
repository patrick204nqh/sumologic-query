---
name: investigate
description: Investigate incidents using Sumo Logic — check monitors, search logs, drill down into patterns, and present a structured incident report with saved evidence artifacts. Use when a user reports a production problem, error spike, latency issue, or wants root cause analysis.
argument-hint: <problem description> e.g. "API errors spiking in production"
---

# Incident Investigation

Systematically investigate problems by checking monitors, searching logs, and presenting a structured incident report. All evidence is saved to `.sumo-query/investigations/` for review and replay.

**Prerequisite:** Verify `sumo-query version` works. If not: `gem install sumologic-query`

**CLI reference:** For command flags and query syntax, read `references/cli-reference.md`.

## Input

The user wants to investigate: **$ARGUMENTS**

If `$ARGUMENTS` is empty, show usage and stop:

> **Usage:** `/sumo-query:investigate <problem description>`
>
> **Examples:**
> - `/sumo-query:investigate API latency spike in production`
> - `/sumo-query:investigate payment service returning 500 errors`
> - `/sumo-query:investigate data ingestion stopped from AWS collectors`

## Artifacts

Initialize the artifact directory at the start:

```bash
ARTIFACT_DIR=$(bash scripts/init-artifacts.sh investigations "$ARGUMENTS")
mkdir -p "$ARTIFACT_DIR/evidence"
```

For **every** `sumo-query` command:

1. Save output with `-o "$ARTIFACT_DIR/evidence/NN-description.json"`
2. Append the command to `$ARTIFACT_DIR/queries.sh` with a phase comment

Use sequential numbering: `01-monitors-critical.json`, `02-search-initial.json`, etc.

## Workflow

### Phase 1: Parse the Problem

Extract from `$ARGUMENTS`:
- **Symptoms**: errors, latency, downtime, missing data
- **Affected service**: derive `_sourceCategory`, `_sourceHost`, or keywords
- **Time window**: default `-1h` to `now` if not specified

Tell the user your understanding before proceeding.

### Phase 2: Discover Log Sources

**Skip** if source category is already known.

```bash
sumo-query search \
  -q '<keyword> | count by _sourceCategory, _sourceName | sort by _count desc' \
  -f '-1h' -t 'now' -a -l 30 -o "$ARTIFACT_DIR/evidence/01-source-discovery.json"
```

Or use: `sumo-query discover-source-metadata -k "<keyword>" -l 20`

Tell the user which sources were found and which you'll use.

### Phase 3: Check Monitors & Health

Run in parallel:

```bash
sumo-query list-monitors -s Critical -l 20 -o "$ARTIFACT_DIR/evidence/02-monitors-critical.json"
sumo-query list-monitors -s Warning -l 20 -o "$ARTIFACT_DIR/evidence/03-monitors-warning.json"
sumo-query list-health-events -l 30 -o "$ARTIFACT_DIR/evidence/04-health-events.json"
```

### Phase 4: Initial Log Search

Construct a targeted search using the discovered source category:

```bash
sumo-query search -q '<scope> <error keywords>' -f <from> -t <to> -l 30 \
  -o "$ARTIFACT_DIR/evidence/05-search-initial.json"
```

### Phase 5: Aggregate & Drill Down

Run aggregation queries to quantify the problem — error count over time, breakdown by type/source, top error messages. Add `-a` flag for aggregations.

### Phase 6: Correlate

Look for correlation across services or time. Compare error hosts with healthy hosts.

### Phase 7: Present Incident Report

Format findings as:

```
## Incident Report

### Summary
<One-paragraph summary>

### Timeline
- **[time]** — First occurrence
- **[time]** — Error rate increased
- **[time]** — Current state

### Affected Systems
- **Source(s):** <source categories, hosts>
- **Monitor(s):** <triggered monitors>
- **Impact:** <scope>

### Root Cause Analysis
<What logs suggest> — Evidence: <specific messages> — Confidence: <high/medium/low>

### Error Patterns
| Error | Count | First Seen | Last Seen |
|-------|-------|------------|-----------|

### Recommendations
1. <Immediate action>
2. <Next investigation step>
3. <Long-term prevention>
```

### Finalize Artifacts

Write the report and evidence index:

1. **`$ARTIFACT_DIR/report.md`** — Full incident report
2. **`$ARTIFACT_DIR/index.md`** — Evidence index:

```markdown
# Evidence Index

| # | Phase | Description | File | Verify |
|---|-------|-------------|------|--------|
| 1 | Monitors | Critical monitors | evidence/02-monitors-critical.json | `jq '.monitors \| length'` |

## How to verify
1. Review evidence: `ls $ARTIFACT_DIR/evidence/`
2. Re-run all queries: `bash $ARTIFACT_DIR/queries.sh`
```

Tell the user: `Artifacts saved to: $ARTIFACT_DIR/`

## Constraints

- **Read-only**: Only search and read data. Never modify monitors, collectors, or configuration.
- **Safe defaults**: Always use `--limit`. Start with `-l 30` for raw logs, `-l 100` for aggregations.
- **No interactive mode**: Never use the `-i` flag.
- **Always save artifacts** to `.sumo-query/investigations/`.
- Maximum 10 search queries per investigation to avoid API rate limits.
- If a command fails, adapt the query and try again.
- If the problem is unclear, ask clarifying questions before running queries.
