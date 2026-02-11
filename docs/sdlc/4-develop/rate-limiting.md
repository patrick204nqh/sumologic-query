# Rate Limiting Configuration

## Sumo Logic API Rate Limits

According to [Sumo Logic's documentation](https://www.sumologic.com/help/docs/api/collector-management/collector-api-methods-examples/#rate-limiting):

- **4 API requests per second** per user
- **10 concurrent requests** per access key

When exceeded, you'll receive a `429 Rate Limit Exceeded` error.

## Default Settings

```bash
# Balanced defaults (5 workers, 250ms delay)
sumo-query sources -o sources.json
```

## Configuration

Adjust via environment variables:

```bash
# Faster (higher rate limit risk)
export SUMO_MAX_WORKERS=8
export SUMO_REQUEST_DELAY=0.15

# Safer (slower)
export SUMO_MAX_WORKERS=2
export SUMO_REQUEST_DELAY=0.5

# Your query
sumo-query sources -o sources.json
```

## Troubleshooting 429 Errors

If you see rate limit errors:

```bash
# Reduce workers
export SUMO_MAX_WORKERS=2

# Increase delay
export SUMO_REQUEST_DELAY=0.5

# Retry
sumo-query sources -o sources.json
```

## Ruby API

```ruby
config = Sumologic::Configuration.new
config.max_workers = 2
config.request_delay = 0.5

client = Sumologic::Client.new(config)
sources = client.list_all_sources
```

## Tips

- Start with defaults
- Reduce workers if sharing API credentials
- Increase delay if hitting rate limits consistently
- Run large jobs during off-peak hours
