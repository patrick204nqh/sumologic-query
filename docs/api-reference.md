# API Reference

Complete reference for using the Sumo Logic Query Tool as a Ruby library.

## Table of Contents

- [Installation](#installation)
- [Client](#client)
- [Configuration](#configuration)
- [Search Operations](#search-operations)
- [Metadata Operations](#metadata-operations)
- [Error Handling](#error-handling)
- [Examples](#examples)

## Installation

Add to your `Gemfile`:

```ruby
gem 'sumologic-query'
```

Or install directly:

```bash
gem install sumologic-query
```

Then require in your code:

```ruby
require 'sumologic'
```

## Client

### Initialization

```ruby
client = Sumologic::Client.new(
  access_id: 'your_access_id',      # Required
  access_key: 'your_access_key',     # Required
  deployment: 'us2',                 # Optional, default: 'us2'
  timeout: 300                       # Optional, default: 300 seconds
)
```

#### Parameters

- `access_id` (String, required): Sumo Logic Access ID
- `access_key` (String, required): Sumo Logic Access Key
- `deployment` (String, optional): Deployment region
  - Valid values: `us1`, `us2`, `eu`, `au`, `ca`, `de`, `jp`, `in`, `fed`
  - Default: `us2`
- `timeout` (Integer, optional): Search timeout in seconds
  - Default: `300` (5 minutes)
  - Maximum: `600` (10 minutes)

#### Using Environment Variables

```ruby
# Reads from SUMO_ACCESS_ID, SUMO_ACCESS_KEY, SUMO_DEPLOYMENT
client = Sumologic::Client.new(
  access_id: ENV['SUMO_ACCESS_ID'],
  access_key: ENV['SUMO_ACCESS_KEY'],
  deployment: ENV.fetch('SUMO_DEPLOYMENT', 'us2')
)
```

## Configuration

The `Configuration` class can be used independently:

```ruby
config = Sumologic::Configuration.new(
  access_id: 'your_access_id',
  access_key: 'your_access_key',
  deployment: 'us2',
  timeout: 300
)

# Access configuration values
config.api_url      # => "https://api.us2.sumologic.com/api/v1"
config.timeout      # => 300
config.deployment   # => "us2"
```

### API URL Mappings

| Deployment | API URL |
|------------|---------|
| `us1` | `https://api.sumologic.com/api/v1` |
| `us2` | `https://api.us2.sumologic.com/api/v1` |
| `eu` | `https://api.eu.sumologic.com/api/v1` |
| `au` | `https://api.au.sumologic.com/api/v1` |
| `ca` | `https://api.ca.sumologic.com/api/v1` |
| `de` | `https://api.de.sumologic.com/api/v1` |
| `jp` | `https://api.jp.sumologic.com/api/v1` |
| `in` | `https://api.in.sumologic.com/api/v1` |
| `fed` | `https://api.fed.sumologic.com/api/v1` |

## Search Operations

### search

Execute a search query against Sumo Logic logs.

```ruby
results = client.search(
  query: 'error',
  from_time: '2025-11-13T14:00:00',
  to_time: '2025-11-13T15:00:00',
  time_zone: 'UTC',
  limit: 1000
)
```

#### Parameters

- `query` (String, required): Sumo Logic query string
  - Supports full Sumo Logic query language
  - Examples: `'error'`, `'* | count by status_code'`
- `from_time` (String, required): Start time in ISO 8601 format
  - Format: `YYYY-MM-DDTHH:MM:SS`
  - Example: `'2025-11-13T14:00:00'`
- `to_time` (String, required): End time in ISO 8601 format
  - Format: `YYYY-MM-DDTHH:MM:SS`
  - Example: `'2025-11-13T15:00:00'`
- `time_zone` (String, optional): Time zone for the query
  - Default: `'UTC'`
  - Examples: `'America/New_York'`, `'Europe/London'`
- `limit` (Integer, optional): Maximum number of messages to return
  - Default: `nil` (no limit)
  - Note: Applied after fetching all results

#### Return Value

Returns an `Enumerator` that yields message hashes:

```ruby
results.each do |message|
  # message is a Hash with 'map' key containing fields
  puts message['map']['_messagetime']
  puts message['map']['message']
  puts message['map']['_sourceCategory']
end
```

#### Message Structure

```ruby
{
  "map" => {
    "_messagetime" => "1731506400123",      # Unix timestamp (ms)
    "_sourceCategory" => "prod/api",        # Source category
    "_sourceName" => "api-server-01",       # Source name
    "_sourceHost" => "10.0.1.42",          # Source host
    "message" => "Error processing request", # Log message
    # ... additional parsed fields
  }
}
```

#### Example: Basic Search

```ruby
client = Sumologic::Client.new(
  access_id: ENV['SUMO_ACCESS_ID'],
  access_key: ENV['SUMO_ACCESS_KEY']
)

results = client.search(
  query: 'error',
  from_time: '2025-11-13T14:00:00',
  to_time: '2025-11-13T15:00:00'
)

# Iterate through results
results.each do |message|
  puts message['map']['message']
end

# Or convert to array
messages = results.to_a
puts "Found #{messages.size} messages"
```

#### Example: Aggregation Query

```ruby
results = client.search(
  query: '* | count by status_code',
  from_time: '2025-11-13T14:00:00',
  to_time: '2025-11-13T15:00:00'
)

results.each do |record|
  puts "Status #{record['map']['status_code']}: #{record['map']['_count']} requests"
end
```

#### Example: With Time Zone

```ruby
results = client.search(
  query: 'error',
  from_time: '2025-11-13T09:00:00',
  to_time: '2025-11-13T17:00:00',
  time_zone: 'America/New_York'
)
```

#### Example: With Limit

```ruby
# Get only first 100 results
results = client.search(
  query: 'error',
  from_time: '2025-11-13T14:00:00',
  to_time: '2025-11-13T15:00:00',
  limit: 100
)
```

## Metadata Operations

### list_collectors

List all collectors in your Sumo Logic account.

```ruby
collectors = client.list_collectors
```

#### Return Value

Returns an array of collector hashes:

```ruby
[
  {
    "id" => 123456,
    "name" => "prod-collector",
    "collectorType" => "Hosted",
    "alive" => true,
    "category" => "prod",
    "timeZone" => "UTC",
    # ... additional fields
  },
  # ...
]
```

#### Example

```ruby
collectors = client.list_collectors

collectors.each do |collector|
  status = collector['alive'] ? 'online' : 'offline'
  puts "#{collector['name']} (#{collector['collectorType']}): #{status}"
end

# Filter for active collectors
active = collectors.select { |c| c['alive'] }
puts "Active collectors: #{active.size}/#{collectors.size}"
```

### list_sources

List sources for a specific collector.

```ruby
sources = client.list_sources(collector_id: 123456)
```

#### Parameters

- `collector_id` (Integer, required): Collector ID

#### Return Value

Returns an array of source hashes:

```ruby
[
  {
    "id" => 789012,
    "name" => "application-logs",
    "sourceType" => "LocalFile",
    "category" => "prod/app",
    "alive" => true,
    "contentType" => "Log",
    # ... additional fields
  },
  # ...
]
```

#### Example

```ruby
sources = client.list_sources(collector_id: 123456)

sources.each do |source|
  puts "#{source['name']} (#{source['sourceType']})"
  puts "  Category: #{source['category']}"
  puts "  Status: #{source['alive'] ? 'active' : 'inactive'}"
end
```

### list_all_sources

List all sources from all active collectors.

```ruby
all_sources = client.list_all_sources
```

#### Return Value

Returns an array of hashes, each containing collector info and its sources:

```ruby
[
  {
    "collector" => {
      "id" => 123456,
      "name" => "prod-collector",
      "collectorType" => "Hosted"
    },
    "sources" => [
      {
        "id" => 789012,
        "name" => "application-logs",
        "sourceType" => "LocalFile",
        # ...
      },
      # ... more sources
    ]
  },
  # ... more collectors
]
```

#### Example

```ruby
all_sources = client.list_all_sources

all_sources.each do |item|
  collector = item['collector']
  sources = item['sources']

  puts "Collector: #{collector['name']}"
  puts "  Sources (#{sources.size}):"

  sources.each do |source|
    puts "    - #{source['name']} (#{source['sourceType']})"
  end
end

# Count total sources
total = all_sources.sum { |item| item['sources'].size }
puts "Total sources: #{total}"
```

## Error Handling

The library raises specific error types for different failure scenarios.

### Error Types

#### Sumologic::Error

Base error class for all Sumologic errors.

```ruby
begin
  client.search(...)
rescue Sumologic::Error => e
  puts "Sumo Logic error: #{e.message}"
end
```

#### Sumologic::AuthenticationError

Raised for authentication failures.

```ruby
begin
  client = Sumologic::Client.new(
    access_id: 'invalid',
    access_key: 'invalid'
  )
  client.list_collectors
rescue Sumologic::AuthenticationError => e
  puts "Authentication failed: #{e.message}"
  # Example: "Authentication failed: Invalid credentials"
end
```

**Common causes**:
- Invalid access ID or key
- Credentials not set
- Wrong deployment region

#### Sumologic::TimeoutError

Raised when search job exceeds timeout.

```ruby
begin
  client.search(
    query: 'very_large_query',
    from_time: '2025-01-01T00:00:00',
    to_time: '2025-12-31T23:59:59'
  )
rescue Sumologic::TimeoutError => e
  puts "Search timed out: #{e.message}"
  # Example: "Search job timed out after 300 seconds"
end
```

**Solutions**:
- Reduce time range
- Add more specific filters
- Increase timeout in client initialization
- Use aggregation instead of raw messages

### Example: Comprehensive Error Handling

```ruby
begin
  client = Sumologic::Client.new(
    access_id: ENV['SUMO_ACCESS_ID'],
    access_key: ENV['SUMO_ACCESS_KEY']
  )

  results = client.search(
    query: 'error',
    from_time: '2025-11-13T14:00:00',
    to_time: '2025-11-13T15:00:00'
  )

  results.each do |message|
    process_message(message)
  end

rescue Sumologic::AuthenticationError => e
  puts "❌ Authentication failed: #{e.message}"
  puts "Check your SUMO_ACCESS_ID and SUMO_ACCESS_KEY"
  exit 1

rescue Sumologic::TimeoutError => e
  puts "⏱️  Search timed out: #{e.message}"
  puts "Try reducing the time range or adding filters"
  exit 1

rescue Sumologic::Error => e
  puts "❌ Error: #{e.message}"
  exit 1

rescue StandardError => e
  puts "❌ Unexpected error: #{e.message}"
  puts e.backtrace
  exit 1
end
```

## Examples

### Example 1: Error Analysis

```ruby
require 'sumologic'
require 'json'

client = Sumologic::Client.new(
  access_id: ENV['SUMO_ACCESS_ID'],
  access_key: ENV['SUMO_ACCESS_KEY']
)

# Find errors in last hour
results = client.search(
  query: 'error | count by _sourceCategory',
  from_time: Time.now.utc - 3600,
  to_time: Time.now.utc,
  time_zone: 'UTC'
)

# Group by source
errors_by_source = {}
results.each do |record|
  source = record['map']['_sourceCategory']
  count = record['map']['_count'].to_i
  errors_by_source[source] = count
end

# Display results
puts JSON.pretty_generate(errors_by_source)
```

### Example 2: Collector Inventory

```ruby
require 'sumologic'

client = Sumologic::Client.new(
  access_id: ENV['SUMO_ACCESS_ID'],
  access_key: ENV['SUMO_ACCESS_KEY']
)

# Get all collectors with sources
all_sources = client.list_all_sources

# Generate inventory report
puts "Collector Inventory Report"
puts "=" * 50

all_sources.each do |item|
  collector = item['collector']
  sources = item['sources']

  puts "\n#{collector['name']} (#{collector['collectorType']})"
  puts "-" * 50

  sources.group_by { |s| s['sourceType'] }.each do |type, sources|
    puts "  #{type}: #{sources.size}"
    sources.each do |source|
      puts "    - #{source['name']} → #{source['category']}"
    end
  end
end
```

### Example 3: Export to CSV

```ruby
require 'sumologic'
require 'csv'

client = Sumologic::Client.new(
  access_id: ENV['SUMO_ACCESS_ID'],
  access_key: ENV['SUMO_ACCESS_KEY']
)

results = client.search(
  query: 'error',
  from_time: '2025-11-13T14:00:00',
  to_time: '2025-11-13T15:00:00'
)

CSV.open('errors.csv', 'w') do |csv|
  csv << ['Timestamp', 'Source', 'Message']

  results.each do |message|
    map = message['map']
    csv << [
      map['_messagetime'],
      map['_sourceCategory'],
      map['message']
    ]
  end
end

puts "Exported to errors.csv"
```

### Example 4: Real-time Monitoring

```ruby
require 'sumologic'

client = Sumologic::Client.new(
  access_id: ENV['SUMO_ACCESS_ID'],
  access_key: ENV['SUMO_ACCESS_KEY']
)

# Monitor for errors every 5 minutes
loop do
  from_time = (Time.now - 300).utc.strftime('%Y-%m-%dT%H:%M:%S')
  to_time = Time.now.utc.strftime('%Y-%m-%dT%H:%M:%S')

  results = client.search(
    query: 'error | count',
    from_time: from_time,
    to_time: to_time
  )

  error_count = results.first['map']['_count'].to_i

  if error_count > 100
    puts "⚠️  High error count: #{error_count}"
    # Send alert
  else
    puts "✅ Normal error count: #{error_count}"
  end

  sleep 300 # Wait 5 minutes
end
```

## See Also

- [Examples](examples.md) - More query patterns
- [Architecture](architecture.md) - How it works internally
- [Troubleshooting](troubleshooting.md) - Common issues
