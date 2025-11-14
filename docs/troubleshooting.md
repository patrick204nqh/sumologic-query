# Troubleshooting

Common issues and solutions when using the Sumo Logic Query Tool.

## Table of Contents

- [Authentication Issues](#authentication-issues)
- [Timeout Issues](#timeout-issues)
- [Query Issues](#query-issues)
- [Installation Issues](#installation-issues)
- [Output Issues](#output-issues)
- [Performance Issues](#performance-issues)
- [Getting Help](#getting-help)

## Authentication Issues

### Error: SUMO_ACCESS_ID not set

**Symptom**:
```
Authentication failed: SUMO_ACCESS_ID not set
```

**Cause**: Missing environment variables for credentials.

**Solution**:

1. Export your credentials:
   ```bash
   export SUMO_ACCESS_ID="your_access_id"
   export SUMO_ACCESS_KEY="your_access_key"
   export SUMO_DEPLOYMENT="us2"  # Optional, defaults to us2
   ```

2. Verify they're set:
   ```bash
   echo $SUMO_ACCESS_ID
   echo $SUMO_ACCESS_KEY
   ```

3. Add to your shell profile for persistence:
   ```bash
   # ~/.bashrc or ~/.zshrc
   export SUMO_ACCESS_ID="your_access_id"
   export SUMO_ACCESS_KEY="your_access_key"
   ```

### Error: Authentication failed (401)

**Symptom**:
```
Authentication failed: 401 Unauthorized
```

**Causes**:
- Invalid access ID or access key
- Credentials for wrong deployment
- Access key expired or revoked

**Solutions**:

1. **Verify credentials**: Log in to Sumo Logic and check your access keys:
   - Go to **Administration → Security → Access Keys**
   - Verify the Access ID matches
   - If needed, create a new access key

2. **Check deployment**: Ensure you're using the correct deployment:
   ```bash
   # If you're on US1
   export SUMO_DEPLOYMENT="us1"

   # If you're on EU
   export SUMO_DEPLOYMENT="eu"
   ```

3. **Test credentials**:
   ```bash
   # Try listing collectors to verify authentication
   sumo-query collectors
   ```

### Error: Wrong deployment region

**Symptom**:
```
Failed to connect: Could not resolve host
```

**Cause**: Using wrong deployment region.

**Solution**:

Check your Sumo Logic URL to determine deployment:

| URL Pattern | Deployment |
|-------------|------------|
| `https://service.sumologic.com` | `us1` |
| `https://service.us2.sumologic.com` | `us2` |
| `https://service.eu.sumologic.com` | `eu` |
| `https://service.au.sumologic.com` | `au` |
| `https://service.ca.sumologic.com` | `ca` |

Set the correct deployment:
```bash
export SUMO_DEPLOYMENT="your_deployment"
```

## Timeout Issues

### Error: Search job timed out after 300 seconds

**Symptom**:
```
Timeout Error: Search job timed out after 300 seconds
```

**Causes**:
- Time range too large
- Query returning too many results
- Complex aggregation query
- Querying inactive data

**Solutions**:

1. **Reduce time range**:
   ```bash
   # Instead of 24 hours
   --from '2025-11-13T00:00:00' --to '2025-11-13T23:59:59'

   # Try 1 hour
   --from '2025-11-13T14:00:00' --to '2025-11-13T15:00:00'
   ```

2. **Add specific filters**:
   ```bash
   # Add source category filter
   sumo-query search --query '_sourceCategory=prod/api error' \
     --from '2025-11-13T00:00:00' --to '2025-11-13T23:59:59'
   ```

3. **Use aggregation instead of raw messages**:
   ```bash
   # Instead of all error messages
   sumo-query search --query 'error'

   # Count errors by source
   sumo-query search --query 'error | count by _sourceCategory'
   ```

4. **Limit results**:
   ```bash
   sumo-query search --query 'error' \
     --from '2025-11-13T14:00:00' \
     --to '2025-11-13T15:00:00' \
     --limit 1000
   ```

5. **Test query in Sumo Logic UI first**: Ensure query completes there before using CLI.

## Query Issues

### Empty results

**Symptom**:
```json
{
  "message_count": 0,
  "messages": []
}
```

**Causes**:
- No data in time range
- Wrong source category or filters
- Wrong time zone
- Query syntax error

**Solutions**:

1. **Verify time range**: Ensure data exists in the specified time range:
   ```bash
   # Check if any data exists
   sumo-query search --query '*' \
     --from '2025-11-13T14:00:00' \
     --to '2025-11-13T15:00:00' \
     --limit 10
   ```

2. **Check time zone**: Default is UTC:
   ```bash
   # If your logs are in EST
   sumo-query search --query 'error' \
     --from '2025-11-13T14:00:00' \
     --to '2025-11-13T15:00:00' \
     --time-zone 'America/New_York'
   ```

3. **Verify source categories**: List your sources to check categories:
   ```bash
   sumo-query sources | jq -r '.[].sources[].category' | sort -u
   ```

4. **Test query in UI**: Copy query to Sumo Logic UI to verify syntax and results.

### Query syntax errors

**Symptom**:
```
Failed to create search job: Invalid query syntax
```

**Solutions**:

1. **Quote search terms with spaces**:
   ```bash
   # Correct
   sumo-query search --query '"connection timeout"'

   # Incorrect
   sumo-query search --query 'connection timeout'
   ```

2. **Escape special characters**:
   ```bash
   sumo-query search --query 'error \| warning'
   ```

3. **Test in Sumo Logic UI**: Validate query syntax before using CLI.

4. **Review query language docs**: https://help.sumologic.com/docs/search/

### Rate limit exceeded

**Symptom**:
```
HTTP 429: Rate limit exceeded
```

**Cause**: Too many API requests in short time.

**Solution**:

Wait 1-2 minutes between queries. Sumo Logic enforces rate limits per account:
- Search API: ~20 concurrent searches
- Metadata API: ~100 requests/minute

```bash
# Add delay between queries
sumo-query search --query 'error' ...
sleep 60
sumo-query search --query 'warning' ...
```

## Installation Issues

### Gem installation fails

**Symptom**:
```
ERROR: Failed to build gem native extension
```

**Cause**: Missing Ruby or Bundler.

**Solution**:

1. **Check Ruby version**:
   ```bash
   ruby --version  # Should be 2.7 or higher
   ```

2. **Install Ruby** (if needed):
   ```bash
   # macOS
   brew install ruby

   # Ubuntu/Debian
   sudo apt-get install ruby-full

   # Using rbenv
   rbenv install 3.3.0
   rbenv global 3.3.0
   ```

3. **Update RubyGems**:
   ```bash
   gem update --system
   ```

4. **Install Bundler**:
   ```bash
   gem install bundler
   ```

### Command not found: sumo-query

**Symptom**:
```bash
sumo-query: command not found
```

**Cause**: Gem bin directory not in PATH.

**Solution**:

1. **Find gem bin directory**:
   ```bash
   gem environment | grep "EXECUTABLE DIRECTORY"
   ```

2. **Add to PATH**:
   ```bash
   # Add to ~/.bashrc or ~/.zshrc
   export PATH="$HOME/.gem/ruby/3.3.0/bin:$PATH"
   ```

3. **Or use bundle exec**:
   ```bash
   bundle exec sumo-query search --query 'error' ...
   ```

### Homebrew installation fails

**Symptom**:
```
Error: No available formula with the name "sumologic-query"
```

**Solution**:

1. **Tap the repository first**:
   ```bash
   brew tap patrick204nqh/tap
   brew install sumologic-query
   ```

2. **Or install from RubyGems instead**:
   ```bash
   gem install sumologic-query
   ```

## Output Issues

### Output truncated or garbled

**Symptom**: Output is cut off or shows encoding errors.

**Solutions**:

1. **Save to file instead of stdout**:
   ```bash
   sumo-query search --query 'error' \
     --from '2025-11-13T14:00:00' \
     --to '2025-11-13T15:00:00' \
     --output results.json
   ```

2. **Use UTF-8 encoding**:
   ```bash
   export LANG=en_US.UTF-8
   export LC_ALL=en_US.UTF-8
   ```

3. **Pipe to jq for formatting**:
   ```bash
   sumo-query search --query 'error' ... | jq '.'
   ```

### JSON parsing errors

**Symptom**: Can't parse output JSON in other tools.

**Solutions**:

1. **Validate JSON output**:
   ```bash
   sumo-query search --query 'error' ... | jq empty
   ```

2. **Pretty print**:
   ```bash
   sumo-query search --query 'error' ... | jq '.'
   ```

3. **Extract specific fields**:
   ```bash
   sumo-query search --query 'error' ... | jq '.messages[].map.message'
   ```

## Performance Issues

### Queries running slowly

**Symptoms**:
- Searches take 3+ minutes
- Pagination takes long time
- High memory usage

**Solutions**:

1. **Narrow time range**:
   ```bash
   # Good: 1 hour range
   --from '2025-11-13T14:00:00' --to '2025-11-13T15:00:00'

   # Avoid: 24+ hour ranges
   --from '2025-11-01T00:00:00' --to '2025-11-30T23:59:59'
   ```

2. **Add specific filters**:
   ```bash
   # Add source category
   sumo-query search --query '_sourceCategory=prod/api error'

   # Add source name
   sumo-query search --query '_sourceName=api-server-01 error'
   ```

3. **Use aggregations**:
   ```bash
   # Instead of raw messages
   sumo-query search --query 'error'

   # Aggregate
   sumo-query search --query 'error | count by _sourceCategory'
   ```

4. **Limit results**:
   ```bash
   sumo-query search --query 'error' --limit 1000
   ```

5. **Check data volume in UI**: Run query in Sumo Logic UI to see message count estimate.

### Expected performance

Query execution time depends on data volume:

| Messages | Typical Time |
|----------|--------------|
| < 1K | 30-60 seconds |
| 1K - 10K | 1-2 minutes |
| 10K - 100K | 2-3 minutes |
| 100K+ | 3-5 minutes |

Factors affecting performance:
- Time range width
- Number of sources
- Query complexity
- Data volume
- Network latency

## Getting Help

### Enable debug output

```bash
# CLI
sumo-query search --query 'error' --debug ...

# Or with environment variable
export SUMO_DEBUG=1
sumo-query search --query 'error' ...

# Library
$DEBUG = true
client.search(...)
```

### Check system information

```bash
# Ruby version
ruby --version

# Gem version
gem list sumologic-query

# Environment
env | grep SUMO
```

### Collect diagnostic information

When reporting issues, include:

1. **Ruby version**: `ruby --version`
2. **Gem version**: `gem list sumologic-query`
3. **Command used**: Full command with `--debug` flag
4. **Error message**: Complete error output
5. **Expected behavior**: What you expected to happen
6. **Environment**: OS, deployment region

### Support channels

- **Issues**: [GitHub Issues](https://github.com/patrick204nqh/sumologic-query/issues)
- **Discussions**: [GitHub Discussions](https://github.com/patrick204nqh/sumologic-query/discussions)
- **Documentation**: [docs/](.)

### Common error patterns

| Error | Likely Cause | Quick Fix |
|-------|-------------|-----------|
| `401 Unauthorized` | Bad credentials | Check `SUMO_ACCESS_ID/KEY` |
| `429 Rate Limit` | Too many requests | Wait 60 seconds |
| `Timeout` | Query too large | Reduce time range |
| `Empty results` | Wrong time zone | Add `--time-zone` |
| `Command not found` | Not in PATH | Use `bundle exec` |

## See Also

- [Examples](examples.md) - Query patterns and use cases
- [API Reference](api-reference.md) - Ruby library documentation
- [Architecture](architecture.md) - How it works internally
