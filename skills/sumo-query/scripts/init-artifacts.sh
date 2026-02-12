#!/usr/bin/env bash
# Initialize a .sumo-query artifact directory for a skill run.
#
# Usage:
#   source scripts/init-artifacts.sh <skill-type> [slug]
#
# Arguments:
#   skill-type  One of: investigations, discoveries, health-checks, queries
#   slug        Optional short label (spaces become dashes, lowercased, max 40 chars)
#
# Exports:
#   ARTIFACT_DIR  Absolute path to the created directory
#
# Example:
#   source scripts/init-artifacts.sh investigations "API errors spiking"
#   # → .sumo-query/investigations/2026-02-12T14-30-api-errors-spiking/

set -euo pipefail

SKILL_TYPE="${1:?Usage: init-artifacts.sh <skill-type> [slug]}"
RAW_SLUG="${2:-}"

TIMESTAMP="$(date -u +%Y-%m-%dT%H-%M)"

if [ -n "$RAW_SLUG" ]; then
  SLUG=$(echo "$RAW_SLUG" | tr ' ' '-' | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]//g' | cut -c1-40)
  DIR_NAME="${TIMESTAMP}-${SLUG}"
else
  DIR_NAME="${TIMESTAMP}"
fi

ARTIFACT_DIR=".sumo-query/${SKILL_TYPE}/${DIR_NAME}"
mkdir -p "$ARTIFACT_DIR"

# Initialize queries.sh — re-runnable script of every CLI command
cat > "$ARTIFACT_DIR/queries.sh" <<HEADER
#!/usr/bin/env bash
# Re-run this script to reproduce the ${SKILL_TYPE%s} results
# Generated: $(date -u +%Y-%m-%dT%H:%M:%SZ)
set -euo pipefail
DIR="\$(cd "\$(dirname "\$0")" && pwd)"
HEADER
chmod +x "$ARTIFACT_DIR/queries.sh"

export ARTIFACT_DIR
echo "$ARTIFACT_DIR"
