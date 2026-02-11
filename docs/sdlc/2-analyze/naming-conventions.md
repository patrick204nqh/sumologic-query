# Naming Conventions

Naming patterns for sumologic-query codebase.

## Files

| Type        | Convention      | Example                        |
| ----------- | --------------- | ------------------------------ |
| Ruby files  | `snake_case.rb` | `source_metadata_discovery.rb` |
| Test files  | `*_spec.rb`     | `monitor_spec.rb`              |
| Directories | `snake_case`    | `metadata/`, `cli/commands/`   |

## Ruby

| Type              | Convention             | Example            |
| ----------------- | ---------------------- | ------------------ |
| Classes/Modules   | `PascalCase`           | `SourceMetadata`   |
| Constants         | `SCREAMING_SNAKE_CASE` | `VALID_STATUSES`   |
| Methods/Variables | `snake_case`           | `list_collectors`  |
| Predicates        | `snake_case?`          | `debug_enabled?`   |
| Bang methods      | `snake_case!`          | `validate!`        |

## Class Suffixes

| Suffix      | Purpose                | Example                    |
| ----------- | ---------------------- | -------------------------- |
| `*Command`  | CLI command handler    | `ListCollectorsCommand`    |
| `*Fetcher`  | Data fetching          | `MessageFetcher`           |
| (none)      | Domain metadata class  | `Collector`, `Monitor`     |
| (none)      | Value object           | `SourceMetadata`           |

## CLI Commands

- Pattern: `verb-noun` in kebab-case
- Examples: `list-collectors`, `get-monitor`, `export-content`, `discover-source-metadata`
- Mapping: `list-collectors` → method `list_collectors` → class `ListCollectorsCommand`

## Module Organization

- Entry point: `lib/sumologic.rb` requires all submodules via `require_relative`
- Facade: `Client` delegates to domain classes (`Metadata::*`, `Search::*`)
- Mixins: `Loggable` included in metadata classes for logging
- No `init.rb` files — modules defined directly in class files
