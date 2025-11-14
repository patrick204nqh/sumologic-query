# sumo-query

> Query Sumo Logic logs and metadata from the command line.
> Provides read-only access to search logs, list collectors, and list sources.
> More information: <https://github.com/patrick204nqh/sumologic-query>.

- Search for logs containing a specific term:

`sumo-query search --query {{error}} --from {{2025-11-13T14:00:00}} --to {{2025-11-13T15:00:00}}`

- Search logs with source category filter:

`sumo-query search --query {{_sourceCategory=prod/api error}} --from {{2025-11-13T14:00:00}} --to {{2025-11-13T15:00:00}}`

- Search logs and save results to a file:

`sumo-query search --query {{error}} --from {{2025-11-13T14:00:00}} --to {{2025-11-13T15:00:00}} --output {{path/to/results.json}}`

- Count messages by field:

`sumo-query search --query {{* | count by status_code}} --from {{2025-11-13T14:00:00}} --to {{2025-11-13T15:00:00}}`

- Search with timezone and limit results:

`sumo-query search --query {{error}} --from {{2025-11-13T09:00:00}} --to {{2025-11-13T17:00:00}} --time-zone {{America/New_York}} --limit {{100}}`

- List all collectors:

`sumo-query collectors`

- List all sources:

`sumo-query sources`

- List sources and save to file:

`sumo-query sources --output {{path/to/sources.json}}`
