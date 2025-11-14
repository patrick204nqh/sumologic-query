# Contributing to Sumo Logic Query Tool

First off, thank you for considering contributing to sumologic-query! It's people like you that make this tool better for everyone.

## Code of Conduct

This project and everyone participating in it is governed by our [Code of Conduct](CODE_OF_CONDUCT.md). By participating, you are expected to uphold this code.

## How Can I Contribute?

### Reporting Bugs

Before creating bug reports, please check the existing issues to avoid duplicates. When you create a bug report, include as many details as possible:

- **Use a clear and descriptive title**
- **Describe the exact steps to reproduce the problem**
- **Provide specific examples** (queries, time ranges, error messages)
- **Describe the behavior you observed** and what you expected to see
- **Include your environment details**: Ruby version, OS, Sumo Logic deployment

**Example bug report:**

```markdown
### Description
CLI times out even with small time ranges

### Steps to Reproduce
1. Run: `sumo-query --query 'error' --from '2025-11-13T14:00:00' --to '2025-11-13T14:05:00'`
2. Wait for timeout

### Expected Behavior
Should return results within 1-2 minutes

### Actual Behavior
Times out after 5 minutes

### Environment
- Ruby: 3.3.0
- OS: macOS 14.0
- Deployment: us2
```

### Suggesting Enhancements

Enhancement suggestions are tracked as GitHub issues. When creating an enhancement suggestion:

- **Use a clear and descriptive title**
- **Provide a detailed description** of the suggested enhancement
- **Explain why this enhancement would be useful**
- **List examples** of how it would be used

### Pull Requests

1. **Fork the repository** and create your branch from `main`
2. **Make your changes**:
   - Follow the Ruby style guide (enforced by RuboCop)
   - Add tests for new functionality
   - Update documentation as needed
3. **Ensure tests pass**: `bundle exec rake`
4. **Write a clear commit message**:
   ```
   Short (50 chars or less) summary

   More detailed explanation if needed. Wrap at 72 characters.

   - Bullet points are okay
   - Use present tense ("Add feature" not "Added feature")
   - Reference issues: "Fixes #123"
   ```
5. **Create the pull request**

## Development Setup

### Prerequisites

- Ruby 2.7 or higher
- Bundler
- Sumo Logic account with API access (for manual testing)

### Setup Steps

```bash
# Clone your fork
git clone https://github.com/YOUR_USERNAME/sumologic-query.git
cd sumologic-query

# Install dependencies
bundle install

# Run tests
bundle exec rspec

# Run linter
bundle exec rubocop

# Run all checks
bundle exec rake
```

### Running the CLI Locally

```bash
# Set up credentials
export SUMO_ACCESS_ID="your_access_id"
export SUMO_ACCESS_KEY="your_access_key"
export SUMO_DEPLOYMENT="us2"

# Search command
bundle exec bin/sumo-query search --query "error" \
  --from "2025-11-13T14:00:00" \
  --to "2025-11-13T15:00:00"

# Collectors command
bundle exec bin/sumo-query collectors

# Sources command
bundle exec bin/sumo-query sources

# With debug output
SUMO_DEBUG=1 bundle exec bin/sumo-query search --query "error" \
  --from "2025-11-13T14:00:00" \
  --to "2025-11-13T15:00:00"
```

### Running Tests

```bash
# All tests
bundle exec rspec

# Specific test file
bundle exec rspec spec/sumologic/client_spec.rb

# Specific module
bundle exec rspec spec/sumologic/configuration_spec.rb
bundle exec rspec spec/sumologic/http/

# With coverage and documentation format
bundle exec rspec --format documentation

# Run linter
bundle exec rubocop

# Run all checks (tests + linter)
bundle exec rake
```

### Testing Individual Components

```ruby
# Test configuration
bundle exec irb
require './lib/sumologic'
config = Sumologic::Configuration.new(
  access_id: ENV['SUMO_ACCESS_ID'],
  access_key: ENV['SUMO_ACCESS_KEY'],
  deployment: 'us2'
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

This project uses RuboCop to enforce Ruby style guidelines:

```bash
# Check style
bundle exec rubocop

# Auto-fix issues
bundle exec rubocop -A
```

Key style points:
- Use frozen string literals
- 2 spaces for indentation
- 120 character line length
- Descriptive variable names
- Comments for complex logic

## Project Structure

```
sumologic-query/
├── lib/
│   ├── sumologic.rb                    # Main entry point & error classes
│   └── sumologic/
│       ├── version.rb                  # Version constant
│       ├── configuration.rb            # Configuration management
│       ├── client.rb                   # Main client facade
│       ├── cli.rb                      # Thor-based CLI
│       ├── http/
│       │   ├── authenticator.rb        # API authentication
│       │   └── client.rb               # HTTP request handling
│       ├── search/
│       │   ├── job.rb                  # Search job creation
│       │   ├── poller.rb               # Job status polling
│       │   └── paginator.rb            # Result pagination
│       └── metadata/
│           ├── collector.rb            # Collector operations
│           └── source.rb               # Source operations
├── bin/
│   └── sumo-query                      # CLI executable
├── spec/
│   ├── spec_helper.rb                  # Test configuration
│   └── sumologic/
│       ├── client_spec.rb              # Client tests
│       ├── configuration_spec.rb       # Configuration tests
│       └── http/
│           └── authenticator_spec.rb   # HTTP auth tests
├── docs/
│   ├── examples.md                     # Query examples
│   ├── architecture.md                 # Architecture docs
│   ├── api-reference.md                # API reference
│   └── troubleshooting.md              # Troubleshooting guide
└── ...
```

## Design Principles

1. **Simplicity First**: Keep the tool focused on querying logs and metadata
2. **Minimal Dependencies**: Use stdlib + Thor for CLI (gracefully degraded)
3. **Read-Only**: No write operations to Sumo Logic
4. **Clear Errors**: User-friendly error messages with context
5. **Fast Execution**: Efficient API usage and pagination
6. **Separation of Concerns**: Modular architecture (HTTP, Search, Metadata, CLI)
7. **Testability**: Loosely coupled components with dependency injection

## Adding New Features

Before adding a new feature:

1. **Open an issue** to discuss the feature
2. **Get feedback** from maintainers
3. **Keep it simple** - does it fit the tool's purpose?
4. **Write tests** - maintain or improve test coverage
5. **Update docs** - README and code comments

## Testing Philosophy

- **Unit tests**: Test individual methods and classes
- **Integration tests**: Test API interactions (mocked)
- **No external calls**: Don't hit real Sumo Logic API in tests
- **Fast execution**: Tests should run in < 5 seconds

## Documentation

When adding new features:

1. Update appropriate documentation:
   - Main README.md for high-level changes
   - docs/examples.md for new query patterns
   - docs/api-reference.md for API changes
   - docs/architecture.md for architectural changes
2. Add code comments for complex logic
3. Update CHANGELOG.md
4. Add tests with documentation

## Release Process

Maintainers will handle releases:

1. Update `lib/sumologic/version.rb`
2. Update `CHANGELOG.md`
3. Create git tag: `git tag v1.0.0`
4. Push tag: `git push --tags`
5. GitHub Actions will build and publish gem

## Getting Help

- **Issues**: [GitHub Issues](https://github.com/patrick204nqh/sumologic-query/issues)
- **Discussions**: [GitHub Discussions](https://github.com/patrick204nqh/sumologic-query/discussions)

## Recognition

Contributors will be recognized in:
- README.md (Contributors section)
- Release notes
- CHANGELOG.md

---

Thank you for contributing! 🎉
