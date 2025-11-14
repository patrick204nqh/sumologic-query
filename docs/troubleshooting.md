# Troubleshooting

Common issues and solutions.

## Authentication Issues

### Missing credentials

**Error**: `SUMO_ACCESS_ID not set`

**Solution**:
```bash
export SUMO_ACCESS_ID="your_access_id"
export SUMO_ACCESS_KEY="your_access_key"
export SUMO_DEPLOYMENT="us2"  # Optional
```

### Invalid credentials

**Error**: `401 Unauthorized`

**Solutions**:
- Verify credentials in Sumo Logic: **Administration → Security → Access Keys**
- Check deployment region matches your Sumo Logic URL
- Try creating a new access key

## Timeout Issues

**Error**: `Search job timed out after 300 seconds`

**Solutions**:
- Reduce time range
- Add source category filter: `_sourceCategory=prod/api error`
- Use aggregation instead of raw messages: `error | count`
- Increase limit: `--limit 1000`

## Query Issues

### Empty results

**Solutions**:
- Verify time range has data: `--query '*' --limit 10`
- Check time zone (default is UTC): `--time-zone 'America/New_York'`
- List sources to verify categories: `sumo-query sources`
- Test query in Sumo Logic UI first

### Syntax errors

**Error**: `Invalid query syntax`

**Solutions**:
- Quote phrases: `--query '"connection timeout"'`
- Test in Sumo Logic UI first
- See [Sumo Logic Search Reference](https://help.sumologic.com/docs/search/)

## Installation Issues

### Command not found

**Error**: `sumo-query: command not found`

**Solutions**:
```bash
# Find gem bin directory
gem environment | grep "EXECUTABLE DIRECTORY"

# Add to PATH (add to ~/.bashrc or ~/.zshrc)
export PATH="$HOME/.gem/ruby/3.3.0/bin:$PATH"

# Or use bundle exec
bundle exec sumo-query search --query 'error' ...
```

## Performance Tips

- **Narrow time ranges**: 1 hour vs 24 hours
- **Add filters**: `_sourceCategory=prod/api`
- **Use aggregations**: `error | count` vs `error`
- **Limit results**: `--limit 1000`

## Debug Mode

Enable debug output to see what's happening:

```bash
# CLI
sumo-query search --query 'error' --debug ...

# Environment variable
export SUMO_DEBUG=1
sumo-query search --query 'error' ...

# Ruby
$DEBUG = true
client.search(...)
```

## Getting Help

**Before reporting issues, collect:**
- Ruby version: `ruby --version`
- Gem version: `gem list sumologic-query`
- Full command with `--debug` flag
- Complete error message

**Support channels:**
- [GitHub Issues](https://github.com/patrick204nqh/sumologic-query/issues)
- [GitHub Discussions](https://github.com/patrick204nqh/sumologic-query/discussions)

## Quick Reference

| Error | Likely Cause | Quick Fix |
|-------|-------------|-----------|
| `401 Unauthorized` | Bad credentials | Check `SUMO_ACCESS_ID/KEY` |
| `Timeout` | Query too large | Reduce time range |
| `Empty results` | Wrong time zone | Add `--time-zone` |
| `Command not found` | Not in PATH | Use `bundle exec` |
