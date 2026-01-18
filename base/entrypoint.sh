#!/bin/bash
set -euo pipefail

# ========================================
# AI Base Image Entrypoint
# ========================================
# This script handles:
# - UID/GID adjustment (runs as root, then switches to app user)
# - Python installation via uv
# - Virtual environment setup at /workspace/.venv
# - Executing /start.sh or CMD
#
# User is responsible for providing /start.sh with:
# - Git repository cloning (if needed)
# - Dependency installation
# - Application startup
# ========================================

PUID=${PUID:-1000}
PGID=${PGID:-1000}
PYTHON_VERSION=${PYTHON_VERSION:-3.12}
export APP_DIR="/workspace"

# ========================================
# User/Group Adjustment (runs as root)
# ========================================
if [ "$(id -u)" = "0" ]; then
    echo "=== AI Base Image Entrypoint ==="
    echo "Target UID: $PUID, Target GID: $PGID"

    CURRENT_UID=$(id -u app)
    CURRENT_GID=$(id -g app)

    # Adjust GID if needed
    if [ "$PGID" != "$CURRENT_GID" ]; then
        EXISTING_GROUP=$(getent group "$PGID" | cut -d: -f1 || true)
        if [ -n "$EXISTING_GROUP" ]; then
            echo "GID $PGID already exists as group '$EXISTING_GROUP'. Using it."
            usermod -g "$EXISTING_GROUP" app
        else
            echo "Changing app group GID to $PGID..."
            groupmod -g "$PGID" app
        fi
    fi

    # Adjust UID if needed
    if [ "$PUID" != "$CURRENT_UID" ]; then
        echo "Changing app user UID to $PUID..."
        usermod -u "$PUID" app
    fi

    # Fix ownership of workspace and mounted volumes
    echo "Fixing permissions for /workspace and mounted subdirectories..."
    chown -R "app:$(id -gn app)" /workspace

    # Switch to app user for the rest
    exec gosu app "$0" "$@"
fi

# ========================================
# Python Installation
# ========================================
export PATH="$HOME/.local/bin:$PATH"

if ! uv python find "$PYTHON_VERSION" >/dev/null 2>&1; then
    echo "Installing Python $PYTHON_VERSION..."
    if ! uv python install "$PYTHON_VERSION"; then
        echo "ERROR: Failed to install Python $PYTHON_VERSION"
        exit 1
    fi
else
    echo "Python $PYTHON_VERSION already installed."
fi

# ========================================
# Virtual Environment Setup
# ========================================
VENV_DIR="/workspace/.venv"

if [ ! -d "$VENV_DIR" ]; then
    echo "Creating virtual environment at $VENV_DIR..."
    if ! uv venv --python "$PYTHON_VERSION" "$VENV_DIR"; then
        echo "ERROR: Failed to create virtual environment"
        exit 1
    fi
fi

# Activate venv via environment variables (works across exec)
export VIRTUAL_ENV="$VENV_DIR"
export UV_PROJECT_ENVIRONMENT="$VENV_DIR"
export PATH="$VENV_DIR/bin:$PATH"

echo "=== Entrypoint complete (venv active) ==="

# ========================================
# Execute start.sh or CMD
# ========================================
if [ -f "/start.sh" ]; then
    echo "Executing /start.sh..."
    exec /start.sh "$@"
else
    echo "No /start.sh found. Executing CMD: $@"
    exec "$@"
fi
