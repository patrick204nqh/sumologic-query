# Interactive Mode Demo

This guide demonstrates the interactive mode features and workflow.

## Quick Start

```bash
# Launch interactive mode
sumo-query search -q 'error' \
  -f '2025-11-13T14:00:00' \
  -t '2025-11-13T15:00:00' \
  -i
```

## Visual Interface

When you run with `-i`, you'll see an interface like this:

```
┌─────────────────────────────────────────────────────────────────────┐
│ 🔍 error_  [12,543 messages | 5 sources | 2024-01-15 10:00-11:30]  │
├─────────────────────────────────────────────────────────────────────┤
│ › 10:23:45 ERROR   prod/api       Connection timeout after 30s      │
│   10:24:12 ERROR   prod/web       Database connection lost          │
│   10:25:33 WARN    prod/api       Slow query detected (2.3s)        │
│   10:26:01 ERROR   prod/queue     Message processing failed         │
│   10:27:15 INFO    prod/api       Request completed                 │
│   ...                                                                │
├─────────────────────────────────────────────────────────────────────┤
│ Preview:                                                             │
│ {                                                                    │
│   "_messagetime": "1705318425000",                                  │
│   "_sourceCategory": "prod/api",                                    │
│   "_sourceName": "api-server-03",                                   │
│   "level": "ERROR",                                                  │
│   "message": "Connection timeout after 30s",                        │
│   "trace_id": "abc123..."                                           │
│ }                                                                    │
└─────────────────────────────────────────────────────────────────────┘
```

## Common Workflows

### 1. Finding Specific Errors

```bash
# Search for errors
sumo-query search -q 'error' -f '2025-11-13T14:00:00' -t '2025-11-13T15:00:00' -i

# In FZF:
# 1. Type "timeout" to filter messages containing "timeout"
# 2. Press Enter to view selected message
# 3. Press Ctrl-S to save all timeout errors to file
```

### 2. Multi-Select and Export

```bash
# Launch interactive mode
sumo-query search -q '*' -f '2025-11-13T14:00:00' -t '2025-11-13T15:00:00' -i

# In FZF:
# 1. Press Tab on interesting messages to select them
# 2. Use arrow keys to navigate, Tab to select multiple
# 3. Press Ctrl-E to export selected to sumo-export.jsonl
```

### 3. Copying Text from Messages

```bash
# Search logs
sumo-query search -q 'critical' -f '2025-11-13T14:00:00' -t '2025-11-13T15:00:00' -i

# In FZF - Two ways to copy:

# Option 1: Copy entire message to clipboard
# 1. Navigate to the message you want
# 2. Press Enter to select it
# 3. Press Ctrl-Y to copy to clipboard

# Option 2: Select and copy specific text
# 1. Navigate to the message you want
# 2. Press Tab to open in pager (less)
# 3. Use mouse to select specific text
# 4. Press Cmd+C (macOS) or Ctrl+Shift+C (Linux) to copy
# 5. Press 'q' to return to FZF
```

### 4. Filtering by Source Category

```bash
# Search all logs
sumo-query search -q '*' -f '2025-11-13T14:00:00' -t '2025-11-13T15:00:00' -i

# In FZF:
# 1. Type "prod/api" to filter only API logs
# 2. Type "ERROR" to further filter only errors from API
# 3. Select and export specific messages
```

## Keyboard Reference

| Key | Action |
|-----|--------|
| `↑↓` or `j/k` | Navigate up/down |
| `Enter` | Toggle selection (mark/unmark) |
| `Tab` | Open current message in pager (copyable) |
| `Ctrl-A` | Select all messages |
| `Ctrl-D` | Deselect all |
| `Ctrl-S` | Save selected to `sumo-selected.txt` and exit |
| `Ctrl-Y` | Copy selected to clipboard and exit |
| `Ctrl-E` | Export selected to `sumo-export.jsonl` and exit |
| `Ctrl-/` | Toggle preview pane |
| `Ctrl-R` | Reload/refresh |
| `Ctrl-Q` or `Esc` | Quit without saving |

## Tips & Tricks

### 1. Combine with Time Filtering

```bash
# Get last hour of errors interactively
sumo-query search -q 'error' \
  -f "$(date -u -v-1H '+%Y-%m-%dT%H:%M:%S')" \
  -t "$(date -u '+%Y-%m-%dT%H:%M:%S')" \
  -i
```

### 2. Use Limit for Faster Exploration

```bash
# Limit to 100 messages for quick exploration
sumo-query search -q 'error' \
  -f '2025-11-13T14:00:00' \
  -t '2025-11-13T15:00:00' \
  -l 100 \
  -i
```

### 3. Search Within Results

Interactive mode automatically provides fuzzy search across:
- Timestamps
- Source categories
- Source names
- Log levels
- Message content
- All JSON fields

Just start typing in FZF to filter!

### 4. Process Exported Files

After using Ctrl-E to export:

```bash
# Count messages by source
cat sumo-export.jsonl | jq -r '._sourceCategory' | sort | uniq -c

# Extract just error messages
cat sumo-export.jsonl | jq -r '.message'

# Filter by specific field
cat sumo-export.jsonl | jq 'select(.level == "ERROR")'
```

## Requirements

Interactive mode requires FZF to be installed:

```bash
# macOS
brew install fzf

# Ubuntu/Debian
sudo apt-get install fzf

# Fedora
sudo dnf install fzf

# Arch Linux
sudo pacman -S fzf
```

Verify installation:
```bash
which fzf
# Should output: /usr/local/bin/fzf (or similar)
```

## Troubleshooting

### FZF Not Found

If you see:
```
╔════════════════════════════════════════════════════════════╗
║  Interactive mode requires FZF to be installed             ║
╚════════════════════════════════════════════════════════════╝
```

Install FZF using the commands above.

### Clipboard Not Working (Ctrl-Y)

- **macOS**: Should work out of the box with `pbcopy`
- **Linux**: Install `xclip`: `sudo apt-get install xclip`
- **Windows/WSL**: May need additional configuration

### Preview Not Showing

- Press `Ctrl-/` to toggle preview pane
- Ensure terminal width is at least 120 characters for best experience

## See Also

- [Query Examples](queries.md) - More query patterns
- [FZF Documentation](https://github.com/junegunn/fzf) - Learn more FZF features
