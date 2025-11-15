# Architecture Decision Records

This directory contains Architecture Decision Records (ADRs) for significant architectural and design decisions made in this project.

## What is an ADR?

An Architecture Decision Record captures an important architectural decision along with its context and consequences. Each ADR describes a single decision.

## Format

Each ADR follows this structure:
- **Status**: Proposed, Accepted, Deprecated, Superseded
- **Context**: What is the issue that we're seeing
- **Decision**: What we decided to do
- **Consequences**: What becomes easier or harder as a result

## Records

- [001: Performance Optimizations](001-performance-optimizations.md) - Connection pooling and ParallelFetcher pattern
- [002: Radical Simplification](002-radical-simplification.md) - Removing over-engineering and streaming APIs
- [003: Extract Parallel Worker Pattern](003-extract-parallel-worker-pattern.md) - DRY abstraction with consistent naming (Worker, CollectorSourceFetcher, MessageFetcher)
