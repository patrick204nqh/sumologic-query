# Investigation Playbooks

Common investigation patterns using sumo-query for incident response and debugging.

## Incident Response

### 1. Initial Assessment

Start with a broad overview to understand the scope:

```bash
# What sources are generating logs in the affected time range?
sumo-query search -q '* | count by _sourceCategory' -f '-1h' -t 'now' -a

# Error distribution by source
sumo-query search -q 'error OR exception OR fatal | count by _sourceCategory' -f '-1h' -t 'now' -a

# Error timeline
sumo-query search -q 'error | timeslice 5m | count by _timeslice' -f '-1h' -t 'now' -a
```

### 2. Error Deep Dive

Once you identify the problematic source:

```bash
# Get actual error messages
sumo-query search -q '_sourceCategory=prod/api error' -f '-1h' -t 'now' --limit 100

# Group errors by type
sumo-query search -q '_sourceCategory=prod/api | parse "Error: *" as error_type | count by error_type | top 10' -f '-1h' -t 'now' -a

# Find first occurrence
sumo-query search -q '_sourceCategory=prod/api error | sort by _messageTime asc' -f '-2h' -t 'now' --limit 1
```

### 3. Host-Level Investigation

```bash
# Which hosts are affected?
sumo-query search -q '_sourceCategory=prod/api error | count by _sourceHost' -f '-1h' -t 'now' -a

# Logs from a specific host
sumo-query search -q '_sourceHost=web-01 error' -f '-30m' -t 'now'

# Compare healthy vs unhealthy hosts
sumo-query search -q '_sourceCategory=prod/api | count by _sourceHost, level' -f '-1h' -t 'now' -a
```

## Service Health

### API Health Check

```bash
# HTTP status distribution
sumo-query search -q '_sourceCategory=prod/api | parse "status=*" as status | count by status' -f '-1h' -t 'now' -a

# 5xx errors by endpoint
sumo-query search -q '_sourceCategory=prod/api | parse "status=* endpoint=*" as status, endpoint | where status >= 500 | count by endpoint' -f '-1h' -t 'now' -a

# Error rate over time
sumo-query search -q '_sourceCategory=prod/api | parse "status=*" as status | if(status >= 500, 1, 0) as is_error | timeslice 5m | sum(is_error) as errors, count as total by _timeslice' -f '-1h' -t 'now' -a
```

### Latency Analysis

```bash
# Average latency by endpoint
sumo-query search -q '| parse "duration=*ms endpoint=*" as duration, endpoint | avg(duration) by endpoint | sort by _avg desc' -f '-1h' -t 'now' -a

# Slow requests
sumo-query search -q '| parse "duration=*ms" as duration | where duration > 5000' -f '-1h' -t 'now' --limit 50

# Latency percentiles
sumo-query search -q '| parse "duration=*ms endpoint=*" as duration, endpoint | pct(duration, 50, 95, 99) by endpoint' -f '-1h' -t 'now' -a
```

## Security Investigation

### Authentication Issues

```bash
# Failed login attempts
sumo-query search -q '"login failed" OR "authentication failed"' -f '-24h' -t 'now'

# Failed logins by user
sumo-query search -q '"login failed" | parse "user=*" as user | count by user | top 20' -f '-24h' -t 'now' -a

# Failed logins by IP
sumo-query search -q '"login failed" | parse "ip=*" as ip | count by ip | top 20' -f '-24h' -t 'now' -a
```

### Access Pattern Analysis

```bash
# Unusual access patterns
sumo-query search -q '| parse "user=* endpoint=*" as user, endpoint | count by user, endpoint | where _count > 100' -f '-1h' -t 'now' -a

# After-hours activity
sumo-query search -q '| parse "user=*" as user | where _messageTime > "2024-01-15T22:00:00" | count by user' -f '-24h' -t 'now' -a
```

## Database Issues

### Query Performance

```bash
# Slow queries
sumo-query search -q '_sourceCategory=*db* "slow query"' -f '-1h' -t 'now'

# Query execution times
sumo-query search -q '_sourceCategory=*db* | parse "execution_time=*ms" as exec_time | where exec_time > 1000' -f '-1h' -t 'now'
```

### Connection Issues

```bash
# Connection errors
sumo-query search -q '_sourceCategory=*db* ("connection refused" OR "too many connections" OR "connection timeout")' -f '-1h' -t 'now'

# Connection pool status
sumo-query search -q '_sourceCategory=*db* | parse "active_connections=*" as active | timeslice 5m | avg(active) by _timeslice' -f '-1h' -t 'now' -a
```

## Container/Kubernetes

### Pod Health

```bash
# Pod restarts
sumo-query search -q '_sourceCategory=*k8s* "restarting" | count by pod_name' -f '-1h' -t 'now' -a

# OOM kills
sumo-query search -q '_sourceCategory=*k8s* "OOMKilled"' -f '-24h' -t 'now'

# CrashLoopBackOff
sumo-query search -q '_sourceCategory=*k8s* "CrashLoopBackOff"' -f '-1h' -t 'now'
```

### Resource Usage

```bash
# High memory usage warnings
sumo-query search -q '_sourceCategory=*k8s* "memory" "threshold"' -f '-1h' -t 'now'

# CPU throttling
sumo-query search -q '_sourceCategory=*k8s* "cpu" "throttl"' -f '-1h' -t 'now'
```

## Workflow: Investigating an Outage

1. **Identify the time window**
   ```bash
   # When did errors start?
   sumo-query search -q 'error | timeslice 1m | count by _timeslice' -f '-2h' -t 'now' -a
   ```

2. **Find affected services**
   ```bash
   sumo-query search -q 'error | count by _sourceCategory' -f '-30m' -t 'now' -a
   ```

3. **Get error details**
   ```bash
   sumo-query search -q '_sourceCategory=affected/service error' -f '-30m' -t 'now' --limit 50
   ```

4. **Check dependencies**
   ```bash
   # Database errors?
   sumo-query search -q '_sourceCategory=*db* error' -f '-30m' -t 'now'

   # External service errors?
   sumo-query search -q '"timeout" OR "connection refused"' -f '-30m' -t 'now'
   ```

5. **Correlate with deployments**
   ```bash
   sumo-query search -q '"deploy" OR "release" OR "rollout"' -f '-2h' -t 'now'
   ```

6. **Document findings**
   ```bash
   # Save investigation results
   sumo-query search -q '_sourceCategory=affected/service error' -f '-30m' -t 'now' -o incident_logs.json
   ```
