# Commit Convention

This project uses [Conventional Commits](https://www.conventionalcommits.org/) for automated changelog generation and releases.

## Commit Message Format

```
<type>(<scope>): <subject>

<body>

<footer>
```

### Type

The type must be one of the following:

- **feat**: A new feature (triggers minor version bump)
- **fix**: A bug fix (triggers patch version bump)
- **docs**: Documentation only changes
- **style**: Changes that don't affect code meaning (whitespace, formatting)
- **refactor**: Code change that neither fixes a bug nor adds a feature
- **perf**: Performance improvement (triggers patch version bump)
- **test**: Adding or updating tests
- **chore**: Changes to build process, tooling, or dependencies

### Scope (Optional)

The scope provides additional context, such as:
- `cli` - CLI-related changes
- `api` - API client changes
- `search` - Search functionality
- `config` - Configuration changes

### Subject

- Use imperative, present tense: "change" not "changed" nor "changes"
- Don't capitalize first letter
- No period (.) at the end
- Maximum 72 characters

### Body (Optional)

- Use imperative, present tense
- Include motivation for the change
- Contrast with previous behavior

### Footer (Optional)

- Reference GitHub issues: `Closes #123` or `Fixes #456`
- Breaking changes: `BREAKING CHANGE: description`

## Examples

### Feature (Minor Version: 1.1.0 → 1.2.0)

```bash
feat: add JSON export format for search results

Users can now export search results to JSON format using the --format json flag.

Closes #42
```

```bash
feat(cli): add --limit flag to restrict result count

Allows users to limit the number of results returned from a search query.
```

### Bug Fix (Patch Version: 1.1.0 → 1.1.1)

```bash
fix: resolve timeout issue in long-running queries

Increased default timeout from 30s to 60s and added retry logic
for connection errors.

Fixes #89
```

```bash
fix(api): handle rate limiting errors gracefully

Added exponential backoff when encountering 429 responses.
```

### Performance Improvement (Patch Version: 1.1.0 → 1.1.1)

```bash
perf: optimize pagination for large result sets

Reduced memory usage by 40% when processing results with 10k+ records.
```

### Breaking Change (Major Version: 1.0.0 → 2.0.0)

```bash
feat: redesign CLI argument structure

Simplified command structure and improved consistency across commands.

BREAKING CHANGE: --output flag renamed to --format for consistency.
The old --output flag is no longer supported. Update your scripts to use
--format instead.

Migration guide: replace `--output json` with `--format json`
```

### Documentation (No Version Change)

```bash
docs: update README with interactive mode examples

Added section showing how to use FZF integration for log exploration.
```

### Refactoring (No Version Change)

```bash
refactor: extract pagination logic into Worker class

Improved code organization and reusability by creating a dedicated
Worker utility for parallel execution.
```

### Chore (No Version Change)

```bash
chore: update rubocop to 1.50.0

Updated development dependency and fixed new linting warnings.
```

## Release Process

1. **Make your changes** and commit using conventional commits
2. **Update version** in `lib/sumologic/version.rb` when ready to release
3. **Push to main** - workflow will:
   - Detect VERSION change
   - Run tests
   - Generate changelog from commits since last release
   - Create git tag
   - Publish gem to RubyGems
   - Create GitHub Release

## Version Bumping Guide

**When to bump which version:**

- **Major (X.0.0)**: Breaking changes, API changes that require user action
  - Use `BREAKING CHANGE:` in commit footer
  - Example: `1.5.3 → 2.0.0`

- **Minor (x.Y.0)**: New features, backward-compatible additions
  - Use `feat:` commit type
  - Example: `1.5.3 → 1.6.0`

- **Patch (x.y.Z)**: Bug fixes, performance improvements
  - Use `fix:` or `perf:` commit type
  - Example: `1.5.3 → 1.5.4`

## Quick Reference

| Commit Type | Version Bump | Use When |
|-------------|--------------|----------|
| `feat:` | Minor (1.1.0 → 1.2.0) | Adding new features |
| `fix:` | Patch (1.1.0 → 1.1.1) | Fixing bugs |
| `perf:` | Patch (1.1.0 → 1.1.1) | Performance improvements |
| `BREAKING CHANGE:` | Major (1.0.0 → 2.0.0) | Breaking API changes |
| `docs:` | None | Documentation only |
| `style:` | None | Code formatting |
| `refactor:` | None | Code restructuring |
| `test:` | None | Test changes |
| `chore:` | None | Build/tooling changes |

## Tools

To help write conventional commits, consider using:

- [Commitizen](https://github.com/commitizen/cz-cli) - Interactive commit message builder
- [commitlint](https://commitlint.js.org/) - Lint commit messages
- Git hooks with [lefthook](https://github.com/evilmartians/lefthook) - Enforce convention

## Questions?

- See full specification: https://www.conventionalcommits.org/
- Read CONTRIBUTING.md for more guidelines
- Check docs/release-process.md for detailed release workflow
