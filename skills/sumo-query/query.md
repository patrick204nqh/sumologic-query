---
name: query
description: Translate natural language to Sumo Logic queries and execute them. Use when a user describes what they want to find in logs using plain English, like "count errors by source in last hour" or "top 10 slowest endpoints".
argument-hint: <what you want to find> e.g. "count errors by source in last hour"
---

# Smart Query Builder

Translate natural language into Sumo Logic queries and execute them. All results are saved to `.sumo-query/queries/` for review and replay.

**Prerequisite:** Verify `sumo-query version` works. If not: `gem install sumologic-query`

**CLI reference:** For command flags and query syntax, read `references/cli-reference.md`.

## Input

The user asked: **$ARGUMENTS**

If `$ARGUMENTS` is empty, show usage and stop:

> **Usage:** `/sumo-query:query <natural language description>`
>
> **Examples:**
> - `/sumo-query:query count errors by source in the last hour`
> - `/sumo-query:query top 10 slowest API endpoints last 30 minutes`
> - `/sumo-query:query 500 errors in production from 2pm to 3pm EST`

## Artifacts

Initialize the artifact directory at the start:

```bash
ARTIFACT_DIR=$(bash scripts/init-artifacts.sh queries "$ARGUMENTS")
```

For **every** `sumo-query` command, save output with `-o` and append to `queries.sh`.

## Workflow

### Step 1: Parse Intent

Break down `$ARGUMENTS` into:
- **Scope**: sources/categories/hosts (default: all)
- **Filter**: errors, keywords, status codes
- **Parse**: fields to extract
- **Aggregation**: count, avg, sum, pct, top N, group by
- **Time range**: default `-1h` to `now`
- **Limit**: 50 for raw, 100 for aggregations

### Step 2: Discover Sources (if scope is unknown)

If the user mentions a service but you don't know the `_sourceCategory`, discover it:

```bash
sumo-query discover-source-metadata -k "<keyword>" -l 20 -o "$ARTIFACT_DIR/discovery.json"
```

Tell the user which source you found.

**Skip** if the user already specified a `_sourceCategory`.

### Step 3: Build Query

Construct the Sumo Logic query. Read `references/cli-reference.md` for query syntax if needed.

### Step 4: Show Query Plan

Before executing, show:

```
Query:   <the constructed query>
From:    <start time>
To:      <end time>
Mode:    <raw or aggregate>
Limit:   <number>
```

### Step 5: Execute

```bash
sumo-query search \
  -q '<query string>' \
  -f <from> -t <to> -l <limit> \
  [-a]              # add if query uses aggregation
  [-z <timezone>]   # add if non-UTC
  -o "$ARTIFACT_DIR/results.json"
```

Rules:
- Single quotes around `-q` value to prevent shell interpolation
- Add `-a` when query contains: count, avg, sum, min, max, pct, first, last, top, count_distinct
- Always include `-l`
- Never use `-i`

### Step 6: Present Results

- **Aggregation**: formatted table or summary
- **Raw logs**: highlight relevant fields and patterns
- Suggest follow-up queries if useful

### Finalize Artifacts

Write **`$ARTIFACT_DIR/plan.md`** with the query plan.

Tell the user: `Artifacts saved to: $ARTIFACT_DIR/`

## Common Translations

| Natural Language | Sumo Logic Query |
|---|---|
| "count errors by source" | `error \| count by _sourceCategory` |
| "top 10 error messages" | `error \| parse "error: *" as msg \| count by msg \| top 10 msg by _count` |
| "average response time" | `\| json "response_time" as rt \| avg(rt) by endpoint` |
| "error rate over time" | `\| if(status >= 400, 1, 0) as err \| timeslice 5m \| avg(err) by _timeslice` |
| "slow requests over 3s" | `\| json "response_time" as rt \| where rt > 3000` |
| "unique users" | `\| json "user" as user \| count_distinct(user)` |

## Time Translations

| Natural Language | `--from` | `--to` |
|---|---|---|
| "last hour" | `-1h` | `now` |
| "last 30 minutes" | `-30m` | `now` |
| "today" / "last 24h" | `-1d` | `now` |
| "last 7 days" | `-7d` | `now` |

## Constraints

- **Read-only**: Only execute search queries. **Always save artifacts** to `.sumo-query/queries/`.
- **Safe defaults**: Always include `--limit`.
- **No interactive mode**: Never use the `-i` flag.
- If intent is ambiguous, ask the user to clarify before executing.
- If results are empty, suggest broadening scope or time range.
