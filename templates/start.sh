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
