# sumo-query

> Query Sumo Logic logs and metadata from the command line.
> Provides read-only access to search logs, list collectors, discover sources, monitors, folders, and dashboards.
> More information: <https://github.com/patrick204nqh/sumologic-query>.

- Search logs using relative time (supports `-30s`, `-5m`, `-2h`, `-7d`, `-1w`, `-1M`, or `now`):

`sumo-query search --query {{error}} --from {{-1h}} --to {{now}}`

- Search logs with source category filter:

`sumo-query search --query {{_sourceCategory=prod/api error}} --from {{-30m}} --to {{now}}`

- Search with aggregation (count, group by):

`sumo-query search --query {{* | count by _sourceCategory}} --from {{-1h}} --to {{now}} --aggregate`

- Search logs with timezone and limit results:

`sumo-query search --query {{error}} --from {{-1h}} --to {{now}} --time-zone {{America/New_York}} --limit {{100}}`

- Search logs in interactive mode with FZF browser (requires fzf):

`sumo-query search --query {{error}} --from {{-1h}} --to {{now}} --interactive`

- Discover dynamic source names from logs (CloudWatch/ECS/Lambda):

`sumo-query discover-sources --from {{-24h}} --to {{now}} --filter {{_sourceCategory=*ecs*}}`

- List all collectors:

`sumo-query list-collectors`

- List all sources:

`sumo-query list-sources`

- List all monitors (alerting rules):

`sumo-query list-monitors`

- List folders in content library:

`sumo-query list-folders`

- List all dashboards:

`sumo-query list-dashboards`

- Display version information:

`sumo-query version`

---

> This page follows the [tldr-pages style guide](https://github.com/tldr-pages/tldr/blob/main/contributing-guides/style-guide.md).
