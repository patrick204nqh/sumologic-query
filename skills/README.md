# sumo-query Skills for Claude Code

AI-powered skills that teach Claude Code how to use the `sumo-query` CLI for Sumo Logic investigation, querying, and monitoring.

## Prerequisites

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) installed
- [sumo-query](https://github.com/patrick204nqh/sumologic-query) gem installed and configured:
  ```bash
  gem install sumologic-query
  sumo-query version  # verify installation
  ```

## Installation

### Option A: Global (available in all projects)

```bash
cp -r skills/sumo-query ~/.claude/commands/sumo-query
```

Skills appear as: `/sumo-query:investigate`, `/sumo-query:query`, etc.

### Option B: Project-specific

```bash
cp -r skills/sumo-query /path/to/my-project/.claude/commands/sumo-query
```

Skills appear as: `/project:sumo-query:investigate`, etc.

### Option C: Symlink (auto-updates from repo)

```bash
ln -s "$(pwd)/skills/sumo-query" ~/.claude/commands/sumo-query
```

## Available Skills

### `/sumo-query:investigate` — Incident Investigation

Systematically investigate incidents: check monitors, search logs, drill down, and produce a structured incident report.

```
/sumo-query:investigate API errors spiking in production
/sumo-query:investigate payment service returning 500 errors
/sumo-query:investigate data ingestion stopped from AWS collectors
```

### `/sumo-query:query` — Smart Query Builder

Translate natural language into Sumo Logic queries and execute them.

```
/sumo-query:query count errors by source in last hour
/sumo-query:query top 10 slowest API endpoints last 30 minutes
/sumo-query:query error rate per host over the last 6 hours
```

### `/sumo-query:health` — Health Dashboard

Check monitor status, health events, and collector health in one view.

```
/sumo-query:health
/sumo-query:health critical
/sumo-query:health collectors
```

### `/sumo-query:discover` — Infrastructure Discovery

Map your Sumo Logic environment: collectors, sources, dashboards, fields, and apps.

```
/sumo-query:discover
/sumo-query:discover collectors
/sumo-query:discover dashboards
```

### `/sumo-query:_reference` — CLI Reference Guide

Quick reference for all CLI commands, query syntax, and time formats.

```
/sumo-query:_reference commands
/sumo-query:_reference query-syntax
/sumo-query:_reference time
```

## Uninstall

Remove the skills directory from wherever you installed it:

```bash
# Global
rm -rf ~/.claude/commands/sumo-query

# Project-specific
rm -rf .claude/commands/sumo-query
```
