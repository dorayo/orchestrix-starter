#!/bin/bash

# Sync script: orchestrix-mcp-server (closed-source) → orchestrix-starter (open-source)
#
# This script copies the relevant files from the closed-source upstream repo
# to this open-source repo. It is meant to be run manually or via CI.
#
# Usage:
#   UPSTREAM_DIR=/path/to/orchestrix-mcp-server ./scripts/sync-from-upstream.sh
#
# In GitHub Actions, set UPSTREAM_DIR to the checkout path of the private repo.

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info() { echo -e "${GREEN}[SYNC]${NC} $1"; }
warn() { echo -e "${YELLOW}[SYNC]${NC} $1"; }
error() { echo -e "${RED}[SYNC]${NC} $1"; exit 1; }

# Resolve paths
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
STARTER_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
UPSTREAM_DIR="${UPSTREAM_DIR:-$HOME/Codes/orchestrix-mcp-server}"

if [ ! -d "$UPSTREAM_DIR/setup" ]; then
    error "Upstream directory not found or invalid: $UPSTREAM_DIR"
fi

RESOURCE_DIR="$STARTER_DIR/skills/create-project/resources"

echo ""
echo "========================================="
echo "  Sync: upstream → orchestrix-starter    "
echo "========================================="
echo "  Upstream: $UPSTREAM_DIR"
echo "  Target:   $STARTER_DIR"
echo ""

# Sync setup scripts
SCRIPTS_TO_SYNC=(
    "handoff-detector.sh"
    "start-orchestrix.sh"
    "o.md"
    "o-help.md"
    "o-status.md"
)

for file in "${SCRIPTS_TO_SYNC[@]}"; do
    src="$UPSTREAM_DIR/setup/$file"
    dst="$RESOURCE_DIR/$file"

    if [ -f "$src" ]; then
        cp "$src" "$dst"
        info "Synced: $file"
    else
        warn "Not found in upstream: $file"
    fi
done

# Sync core-config template (from content/, not .orchestrix-core/)
src="$UPSTREAM_DIR/content/core-config.yaml"
dst="$RESOURCE_DIR/core-config.template.yaml"

if [ -f "$src" ]; then
    # Replace actual values with placeholders
    sed \
        -e "s/^  name: .*/  name: '{{PROJECT_NAME}}'/" \
        -e "s/^  testCommand: .*/  testCommand: '{{TEST_COMMAND}}'/" \
        -e "s/^    repository_id: .*/    repository_id: '{{REPO_ID}}'/" \
        "$src" > "$dst"
    info "Synced + templatized: core-config.template.yaml"
else
    warn "Not found in upstream: content/core-config.yaml"
fi

echo ""
info "Sync complete. Review changes with: git diff"
echo ""
