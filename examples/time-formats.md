# Time Format Examples

The sumo-query tool supports multiple time formats for maximum flexibility.

## Relative Time (Recommended)

Relative times are the easiest way to query recent logs:

```bash
# Last 30 minutes
sumo-query search -q 'error' -f '-30m' -t 'now'

# Last hour
sumo-query search -q 'error' -f '-1h' -t 'now'

# Last 2 hours
sumo-query search -q 'error' -f '-2h' -t 'now'

# Last 24 hours
sumo-query search -q 'error' -f '-24h' -t 'now'

# Last 7 days
sumo-query search -q 'error' -f '-7d' -t 'now' --limit 100

# Last week
sumo-query search -q 'error' -f '-1w' -t 'now'

# Last 30 days (approximately)
sumo-query search -q 'error' -f '-1M' -t 'now' --limit 1000
```

### Supported Time Units

| Unit | Description | Example |
|------|-------------|---------|
| `s` | Seconds | `-30s` (30 seconds ago) |
| `m` | Minutes | `-15m` (15 minutes ago) |
| `h` | Hours | `-2h` (2 hours ago) |
| `d` | Days | `-7d` (7 days ago) |
| `w` | Weeks | `-1w` (1 week ago) |
| `M` | Months | `-1M` (~30 days ago) |
| `now` | Current time | `now` |

## ISO 8601 Format

Standard ISO 8601 timestamps for precise queries:

```bash
# Specific time range
sumo-query search -q 'error' \
  -f '2025-11-13T14:00:00' \
  -t '2025-11-13T15:00:00'

# With timezone
sumo-query search -q 'error' \
  -f '2025-11-13T14:00:00' \
  -t '2025-11-13T15:00:00' \
  -z 'America/New_York'

# Midnight to midnight
sumo-query search -q 'error' \
  -f '2025-11-13T00:00:00' \
  -t '2025-11-14T00:00:00'
```

## Unix Timestamps

Query using Unix timestamps (seconds or milliseconds):

```bash
# Unix timestamp in seconds (10 digits)
sumo-query search -q 'error' \
  -f '1700000000' \
  -t '1700003600'

# Unix timestamp in milliseconds (13 digits)
sumo-query search -q 'error' \
  -f '1700000000000' \
  -t '1700003600000'

# Mix with relative time
sumo-query search -q 'error' \
  -f '1700000000' \
  -t 'now'
```

## Timezone Support

### IANA Timezone Names (Recommended)

```bash
# UTC (default)
sumo-query search -q 'error' -f '-1h' -t 'now' -z 'UTC'

# US Eastern
sumo-query search -q 'error' -f '-1h' -t 'now' -z 'America/New_York'

# US Pacific
sumo-query search -q 'error' -f '-1h' -t 'now' -z 'America/Los_Angeles'

# UK
sumo-query search -q 'error' -f '-1h' -t 'now' -z 'Europe/London'

# Australian Eastern (Sydney/Melbourne)
sumo-query search -q 'error' -f '-1h' -t 'now' -z 'Australia/Sydney'

# Australian Central (Adelaide)
sumo-query search -q 'error' -f '-1h' -t 'now' -z 'Australia/Adelaide'

# Australian Western (Perth)
sumo-query search -q 'error' -f '-1h' -t 'now' -z 'Australia/Perth'
```

### US Timezone Abbreviations

```bash
# Eastern Standard Time
sumo-query search -q 'error' -f '-1h' -t 'now' -z 'EST'

# Pacific Standard Time
sumo-query search -q 'error' -f '-1h' -t 'now' -z 'PST'

# Central Standard Time
sumo-query search -q 'error' -f '-1h' -t 'now' -z 'CST'

# Mountain Standard Time
sumo-query search -q 'error' -f '-1h' -t 'now' -z 'MST'
```

### Australian Timezone Abbreviations

```bash
# Australian Eastern Standard Time (Sydney)
sumo-query search -q 'error' -f '-1h' -t 'now' -z 'AEST'

# Australian Central Standard Time (Adelaide)
sumo-query search -q 'error' -f '-1h' -t 'now' -z 'ACST'

# Australian Western Standard Time (Perth)
sumo-query search -q 'error' -f '-1h' -t 'now' -z 'AWST'
```

### UTC Offset Format

```bash
# UTC+10
sumo-query search -q 'error' -f '-1h' -t 'now' -z '+10:00'

# UTC-5
sumo-query search -q 'error' -f '-1h' -t 'now' -z '-05:00'

# Alternative format
sumo-query search -q 'error' -f '-1h' -t 'now' -z '+1000'
```

## Mixing Time Formats

You can mix different time formats in the same query:

```bash
# Relative start, ISO 8601 end
sumo-query search -q 'error' \
  -f '-24h' \
  -t '2025-11-19T12:00:00'

# Unix timestamp start, relative end
sumo-query search -q 'error' \
  -f '1700000000' \
  -t 'now'

# ISO 8601 start, relative end
sumo-query search -q 'error' \
  -f '2025-11-13T00:00:00' \
  -t 'now'
```

## Common Use Cases

### Last Hour in Different Timezones

```bash
# Australia
sumo-query search -q 'error' -f '-1h' -t 'now' -z 'AEST'

# US East Coast
sumo-query search -q 'error' -f '-1h' -t 'now' -z 'EST'

# Europe
sumo-query search -q 'error' -f '-1h' -t 'now' -z 'Europe/London'
```

### Business Hours Queries

```bash
# Last business day (9 AM - 5 PM Sydney time)
sumo-query search -q 'error' \
  -f '2025-11-18T09:00:00' \
  -t '2025-11-18T17:00:00' \
  -z 'Australia/Sydney'

# Today's business hours so far
sumo-query search -q 'error' \
  -f '2025-11-19T09:00:00' \
  -t 'now' \
  -z 'America/New_York'
```

### Save Results with Auto-Created Directories

```bash
# Output directories are automatically created
sumo-query search -q 'error' \
  -f '-7d' \
  -t 'now' \
  -o logs/weekly/errors.json

# Nested directories work too
sumo-query search -q 'error' \
  -f '-1h' \
  -t 'now' \
  -o reports/$(date +%Y)/$(date +%m)/errors.json
```

## Ruby Library Usage

Using time parser utilities in Ruby:

```ruby
require 'sumologic/utils/time_parser'

# Parse relative times
from_time = Sumologic::Utils::TimeParser.parse('-1h')
to_time = Sumologic::Utils::TimeParser.parse('now')

# Parse Unix timestamps
timestamp = Sumologic::Utils::TimeParser.parse('1700000000')

# Parse ISO 8601
iso_time = Sumologic::Utils::TimeParser.parse('2025-11-13T14:00:00')

# Parse timezones
tz = Sumologic::Utils::TimeParser.parse_timezone('AEST')  # => "Australia/Sydney"
tz = Sumologic::Utils::TimeParser.parse_timezone('EST')   # => "America/New_York"
tz = Sumologic::Utils::TimeParser.parse_timezone('+10:00') # => "+10:00"
```

## Tips

- **Use relative times** for ad-hoc queries - they're easier and more intuitive
- **Use ISO 8601** for scheduled jobs or when you need precise time ranges
- **Unix timestamps** are useful when integrating with other systems
- **Timezone abbreviations** are case-insensitive (`AEST`, `aest`, `Aest` all work)
- **Default timezone** is UTC if not specified
- **Mix formats** freely - use what makes sense for your use case
