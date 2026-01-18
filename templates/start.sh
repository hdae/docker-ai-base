#!/bin/bash
set -euo pipefail

# ========================================
# Start Script (User-provided)
# ========================================
# Entrypoint has already:
# - Adjusted UID/GID
# - Installed Python via uv
# - Created and activated virtual environment
#
# You are responsible for:
# - Cloning repositories (if needed)
# - Installing dependencies
# - Starting your application
#
# Available environment variables from entrypoint:
# - APP_DIR=/workspace
# - VIRTUAL_ENV=/workspace/.venv
# - PYTHON_VERSION
# ========================================

# Ensure APP_DIR is set (fallback if not provided by entrypoint)
APP_DIR="${APP_DIR:-/workspace}"

# ========================================
# Git Clone Helper (Idempotent)
# ========================================
# Clones or updates a Git repository to a specific branch, tag, or commit.
# This is useful for plugins or dependencies that don't conflict with volume mounts.
#
# Usage:
#   clone_or_update <repo_url> <target_dir> [ref]
#
# Parameters:
#   repo_url    - Git repository URL (https or ssh)
#   target_dir  - Target directory (will be created if not exists)
#   ref         - Branch, tag, or commit hash (default: main)
#
# Example:
#   clone_or_update "https://github.com/example/plugin.git" "/workspace/plugins/example" "v1.0.0"
#
clone_or_update() {
    local repo_url="$1"
    local target_dir="$2"
    local ref="${3:-main}"
    
    if [ -d "$target_dir/.git" ]; then
        echo "📦 Updating $target_dir to $ref..."
        cd "$target_dir"
        git fetch origin --quiet
        git checkout "$ref" --quiet
        # Try to pull if it's a branch, ignore errors if it's a tag/commit
        git reset --hard "origin/$ref" 2>/dev/null || git reset --hard "$ref"
        cd - > /dev/null
    else
        echo "📦 Cloning $repo_url to $target_dir..."
        git clone --quiet "$repo_url" "$target_dir"
        cd "$target_dir"
        git checkout "$ref" --quiet
        cd - > /dev/null
    fi
    
    echo "✓ Repository ready at $target_dir (ref: $ref)"
}

# ========================================
# Example: Clone plugins
# ========================================
# Uncomment and customize as needed:
# clone_or_update "https://github.com/example/plugin1.git" "$APP_DIR/plugins/plugin1" "main"
# clone_or_update "https://github.com/example/plugin2.git" "$APP_DIR/plugins/plugin2" "v2.1.0"

# ========================================
# Dependencies
# ========================================
if [ -f "$APP_DIR/app/requirements.txt" ]; then
    echo "Installing dependencies..."
    uv pip install -r "$APP_DIR/app/requirements.txt"
fi

# ========================================
# Start Application
# ========================================
echo "Starting application..."

# Option 1: Run a specific command
# exec python app/main.py

# Option 2: Run arguments passed to the container
if [ $# -gt 0 ]; then
    exec "$@"
else
    echo "No command provided. Starting bash..."
    exec bash
fi
