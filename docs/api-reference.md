# API Reference

Using the Sumo Logic Query Tool as a Ruby library.

## Installation

```ruby
# Gemfile
gem 'sumologic-query'

# Or directly
gem install sumologic-query
```

## Quick Start

```ruby
require 'sumologic'

client = Sumologic::Client.new(
  access_id: ENV['SUMO_ACCESS_ID'],
  access_key: ENV['SUMO_ACCESS_KEY'],
  deployment: 'us2'  # Optional, default: 'us2'
)
```

## Client Methods

### search

Execute a search query.

```ruby
results = client.search(
  query: 'error',                          # Required
  from_time: '2025-11-13T14:00:00',       # Required (ISO 8601)
  to_time: '2025-11-13T15:00:00',         # Required (ISO 8601)
  time_zone: 'UTC',                        # Optional, default: 'UTC'
  limit: 1000                              # Optional, default: nil (no limit)
)

# Iterate results
results.each do |message|
  puts message['map']['message']
  puts message['map']['_sourceCategory']
end

# Or convert to array
messages = results.to_a
```

### list_collectors

List all collectors.

```ruby
collectors = client.list_collectors

collectors.each do |collector|
  puts collector['name']
  puts collector['alive']  # true/false
  puts collector['collectorType']  # Hosted, Installed, etc.
end
```

### list_sources

List sources for a specific collector.

```ruby
sources = client.list_sources(collector_id: 123456)

sources.each do |source|
  puts source['name']
  puts source['sourceType']
  puts source['category']
end
```

### list_all_sources

List all sources from all active collectors.

```ruby
all_sources = client.list_all_sources

all_sources.each do |item|
  collector = item['collector']
  sources = item['sources']

  puts "#{collector['name']}: #{sources.size} sources"
end
```

## Configuration

### Deployments

Valid deployment values:

| Deployment | API URL |
|------------|---------|
| `us1` | api.sumologic.com |
| `us2` | api.us2.sumologic.com (default) |
| `eu` | api.eu.sumologic.com |
| `au` | api.au.sumologic.com |
| `ca` | api.ca.sumologic.com |

### Timeout

```ruby
client = Sumologic::Client.new(
  access_id: ENV['SUMO_ACCESS_ID'],
  access_key: ENV['SUMO_ACCESS_KEY'],
  timeout: 600  # 10 minutes (default: 300)
)
```

## Error Handling

```ruby
begin
  results = client.search(
    query: 'error',
    from_time: '2025-11-13T14:00:00',
    to_time: '2025-11-13T15:00:00'
  )
rescue Sumologic::AuthenticationError => e
  puts "Auth failed: #{e.message}"
rescue Sumologic::TimeoutError => e
  puts "Timeout: #{e.message}"
rescue Sumologic::Error => e
  puts "Error: #{e.message}"
end
```

**Error types:**
- `AuthenticationError` - Invalid credentials
- `TimeoutError` - Search exceeded timeout
- `Error` - General errors

## Examples

### Search with aggregation

```ruby
results = client.search(
  query: 'error | count by _sourceCategory',
  from_time: '2025-11-13T14:00:00',
  to_time: '2025-11-13T15:00:00'
)

results.each do |record|
  category = record['map']['_sourceCategory']
  count = record['map']['_count']
  puts "#{category}: #{count} errors"
end
```

### Export to CSV

```ruby
require 'csv'

results = client.search(
  query: 'error',
  from_time: '2025-11-13T14:00:00',
  to_time: '2025-11-13T15:00:00',
  limit: 1000
)

CSV.open('errors.csv', 'w') do |csv|
  csv << ['Time', 'Source', 'Message']

  results.each do |message|
    map = message['map']
    csv << [map['_messagetime'], map['_sourceCategory'], map['message']]
  end
end
```

### List active collectors

```ruby
collectors = client.list_collectors
active = collectors.select { |c| c['alive'] }

puts "Active: #{active.size}/#{collectors.size}"
active.each do |c|
  puts "- #{c['name']} (#{c['collectorType']})"
end
```

### Find sources by category

```ruby
all_sources = client.list_all_sources

all_sources.each do |item|
  prod_sources = item['sources'].select { |s| s['category']&.include?('prod') }

  if prod_sources.any?
    puts "#{item['collector']['name']}:"
    prod_sources.each { |s| puts "  - #{s['name']}" }
  end
end
```

## Response Format

### Search Response

```ruby
{
  "map" => {
    "_messagetime" => "1731506400123",
    "_sourceCategory" => "prod/api",
    "_sourceName" => "api-server-01",
    "message" => "Error processing request"
  }
}
```

### Collector Response

```ruby
{
  "id" => 123456,
  "name" => "prod-collector",
  "collectorType" => "Hosted",
  "alive" => true
}
```

### Source Response

```ruby
{
  "id" => 789012,
  "name" => "application-logs",
  "sourceType" => "LocalFile",
  "category" => "prod/app",
  "alive" => true
}
```

## Tips

- **Use enumerators**: Results are lazy-loaded for memory efficiency
- **Handle errors**: Always wrap API calls in error handling
- **Limit results**: Use `limit` parameter for large datasets
- **Test queries**: Validate queries in Sumo Logic UI first

For more examples, see [examples/queries.md](../examples/queries.md).
