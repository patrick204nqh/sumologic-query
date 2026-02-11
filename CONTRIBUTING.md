# Contributing to Sumo Logic Query Tool

Thank you for considering contributing! This guide will help you get started.

## How to Contribute

### Reporting Bugs

Check existing issues first, then create a new one with:

- **Clear title** describing the issue
- **Steps to reproduce** the problem
- **Expected vs actual behavior**
- **Environment details**: Ruby version, OS, deployment

**Example:**
```markdown
### Bug: Timeout with small time range

**Steps:**
1. Run: `sumo-query search --query 'error' --from '2025-11-13T14:00:00' --to '2025-11-13T14:05:00'`
2. Wait for timeout

**Expected:** Results within 1-2 minutes
**Actual:** Times out after 5 minutes

**Environment:** Ruby 3.3.0, macOS 14.0, us2 deployment
```

### Suggesting Features

Open an issue with:
- Clear description of the feature
- Why it would be useful
- Example use cases

### Pull Requests

1. Fork and create a branch from `main`
2. Make your changes following our style guide
3. Add tests for new functionality
4. Update documentation
5. Ensure `bundle exec rake` passes
6. Write a clear commit message using [Conventional Commits](.github/commit-convention.md)
7. Submit the pull request

**Commit message format:**

We use [Conventional Commits](.github/commit-convention.md) for automated changelog generation.

```bash
# Feature
feat(cli): add JSON export format

# Bug fix
fix: resolve timeout issue in long-running queries

# Breaking change
feat: redesign CLI argument structure

BREAKING CHANGE: --output flag renamed to --format
```

## Development Setup

### Prerequisites

- Ruby 2.7+
- Bundler
- Sumo Logic account (for testing)

### Quick Start

```bash
# Clone and install
git clone https://github.com/YOUR_USERNAME/sumologic-query.git
cd sumologic-query
bundle install

# Run tests
bundle exec rspec

# Run linter
bundle exec rubocop

# Run all checks
bundle exec rake
```

### Testing Locally

```bash
# Set credentials
export SUMO_ACCESS_ID="your_access_id"
export SUMO_ACCESS_KEY="your_access_key"
export SUMO_DEPLOYMENT="us2"

# Test commands
bundle exec bin/sumo-query search --query "error" \
  --from "2025-11-13T14:00:00" \
  --to "2025-11-13T15:00:00"

bundle exec bin/sumo-query collectors
bundle exec bin/sumo-query sources

# Debug mode
SUMO_DEBUG=1 bundle exec bin/sumo-query search --query "error" \
  --from "2025-11-13T14:00:00" \
  --to "2025-11-13T15:00:00"
```

### Running Tests

```bash
# All tests
bundle exec rspec

# Specific files
bundle exec rspec spec/sumologic/client_spec.rb
bundle exec rspec spec/sumologic/http/

# With documentation format
bundle exec rspec --format documentation

# Linter
bundle exec rubocop
bundle exec rubocop -A  # Auto-fix

# All checks
bundle exec rake
```

### Interactive Testing

```bash
bundle exec irb
require './lib/sumologic'

# Test configuration
config = Sumologic::Configuration.new(
  access_id: ENV['SUMO_ACCESS_ID'],
  access_key: ENV['SUMO_ACCESS_KEY']
)
puts config.api_url

# Test client
client = Sumologic::Client.new(
  access_id: ENV['SUMO_ACCESS_ID'],
  access_key: ENV['SUMO_ACCESS_KEY']
)
collectors = client.list_collectors
puts collectors.first
```

## Code Style

We use RuboCop for style enforcement:

```bash
bundle exec rubocop        # Check
bundle exec rubocop -A     # Auto-fix
```

**Key conventions:**
- Frozen string literals
- 2 spaces indentation
- 120 character line length
- Descriptive variable names
- Comments for complex logic

## Project Structure

```
lib/sumologic/
├── configuration.rb       # Config management
├── client.rb             # Main facade
├── cli.rb                # CLI interface
├── http/                 # HTTP layer
├── search/               # Search operations
└── metadata/             # Metadata operations

spec/                     # Tests
examples/queries.md       # Query examples
docs/                     # Reference docs
```

## Design Principles

1. **Simplicity** - Focus on logs and metadata
2. **Minimal dependencies** - Stdlib + Thor
3. **Read-only** - No write operations
4. **Clear errors** - Helpful error messages
5. **Modular** - Separation of concerns
6. **Testable** - Loose coupling

## Adding Features

Before implementing:

1. **Open an issue** to discuss
2. **Get feedback** from maintainers
3. **Keep it simple** - fits the tool's purpose?
4. **Write tests** - maintain coverage
5. **Update docs** - README and relevant docs

## Adding a CLI Command

Most contributions add a new CLI command. Every command touches these files in order:

### 1. Metadata class — `lib/sumologic/metadata/<resource>.rb`

Handles the raw API call. Use `@http` for v1 endpoints or `@http_v2` for v2 (Content Library, Dashboards, Folders).

```ruby
# frozen_string_literal: true

require_relative 'loggable'

module Sumologic
  module Metadata
    class Widget
      include Loggable

      def initialize(http_client:)
        @http = http_client          # or http_v2 for v2 API
      end

      def list
        data = @http.request(method: :get, path: '/widgets')
        data['widgets'] || []
      rescue StandardError => e
        raise Error, "Failed to list widgets: #{e.message}"
      end
    end
  end
end
```

### 2. Command class — `lib/sumologic/cli/commands/<command>_command.rb`

Calls the client facade and outputs JSON.

```ruby
# frozen_string_literal: true

require_relative 'base_command'

module Sumologic
  class CLI < Thor
    module Commands
      class ListWidgetsCommand < BaseCommand
        def execute
          warn 'Fetching widgets...'
          widgets = client.list_widgets
          output_json(total: widgets.size, widgets: widgets)
        end
      end
    end
  end
end
```

### 3. Register in `lib/sumologic/cli.rb`

Add `require_relative` at the top, then a Thor command method that delegates to the command class.

### 4. Facade method in `lib/sumologic/client.rb`

Initialize the metadata class in `#initialize` and add a public method that delegates to it.

### 5. Require in `lib/sumologic.rb`

Add `require_relative 'sumologic/metadata/<resource>'` in the metadata section.

### 6. Tests

Add these specs:

- `spec/sumologic/metadata/<resource>_spec.rb` — API calls, error handling
- `spec/sumologic/cli/commands/commands_spec.rb` — add a test for the new command
- `spec/sumologic/client_spec.rb` — add `respond_to` expectation

## Documentation

When adding features, update:

- `README.md` - If it affects quick start or main usage
- `examples/queries.md` - If adding query patterns
- `docs/api-reference.md` - If changing API
- `docs/architecture.md` - If changing design
- `CHANGELOG.md` - Always

Keep docs simple and focused on key concepts.

## Testing Philosophy

- **Unit tests** - Individual methods/classes
- **Mocked APIs** - No real Sumo Logic calls
- **Fast** - Tests run in < 5 seconds
- **Clear** - Easy to understand failures

## Release Process

Releases are automated. Maintainers:

1. Make changes using [conventional commits](.github/commit-convention.md)
2. Update `lib/sumologic/version.rb` when ready to release
3. Push to `main`
4. GitHub Actions automatically:
   - Generates changelog from commits
   - Creates git tag
   - Publishes gem to RubyGems
   - Creates GitHub Release

See [.github/commit-convention.md](.github/commit-convention.md) for commit format and examples.

## Getting Help

- [GitHub Issues](https://github.com/patrick204nqh/sumologic-query/issues)
- [GitHub Discussions](https://github.com/patrick204nqh/sumologic-query/discussions)

## Recognition

Contributors are recognized in:
- Release notes
- CHANGELOG.md

---

Thank you for contributing! 🎉
