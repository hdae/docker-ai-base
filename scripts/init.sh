#!/usr/bin/env bash
# ========================================
# docker-ai-base: Template Initializer
# ========================================
# Copies files from templates/ into the destination directory, renames the
# template README so it does not shadow the user's own project README, and
# ensures start.sh is executable.
#
# Usage:
#   scripts/init.sh <destination>
# ========================================

set -euo pipefail

usage() {
    cat <<'USAGE'
Usage: scripts/init.sh <destination>

Copies the docker-ai-base templates into <destination> and prepares the
project for first use.

Arguments:
  <destination>   Target directory (will be created if it does not exist).
USAGE
}

if [ "$#" -ne 1 ] || [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    usage
    exit 1
fi

DEST="$1"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TEMPLATE_DIR="$REPO_ROOT/templates"

if [ ! -d "$TEMPLATE_DIR" ]; then
    echo "ERROR: template directory not found at $TEMPLATE_DIR" >&2
    exit 1
fi

mkdir -p "$DEST"

# Copy every file (including dotfiles like .env.example) from templates/.
# The trailing /. is intentional: it preserves hidden files.
cp -R "$TEMPLATE_DIR"/. "$DEST"/

# The template README documents template usage and would confuse users who
# open the destination directory looking for their own project README.
if [ -f "$DEST/README.md" ]; then
    mv "$DEST/README.md" "$DEST/TEMPLATE_README.md"
fi

if [ -f "$DEST/start.sh" ]; then
    chmod +x "$DEST/start.sh"
fi

echo "✓ Template initialized at: $DEST"
echo "  Next steps:"
echo "    cd $DEST"
echo "    cp .env.example .env   # optional, edit as needed"
echo "    task up"
