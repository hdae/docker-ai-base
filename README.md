# AI Base Image Template

A minimal, highly adaptable Docker base image for Python/AI applications.

## Overview

This project provides:

- **Base Image** (`hdae/ai-base`): Minimal Debian image with `uv` and `vcstool`
- **Template**: Ready-to-use Docker Compose setup for your projects

## Quick Start

### 1. Build the Base Image

```bash
task build
# or: docker build -t hdae/ai-base ./base
```

### 2. Use in Your Project

Copy files from `templates/` to your project:

```bash
cp -r templates/* /path/to/your-project/
cd /path/to/your-project
task up
```

See [templates/README.md](templates/README.md) for detailed template usage.

## Base Image Features

- **Base**: Debian Bookworm Slim
- **Tools**: `uv` (Python package manager), `vcstool` (multi-repo management)
- **User**: Non-root `app` user with configurable UID/GID at runtime
- **Workdir**: `/workspace`

## Project Structure

```
├── base/              # Base image definition
│   ├── Dockerfile
│   └── entrypoint.sh  # Entrypoint script
├── templates/         # Template for projects
│   ├── docker-compose.yml
│   ├── Taskfile.yml
│   ├── app.repos.yaml
│   ├── start.sh
│   └── README.md
├── Taskfile.yml       # Build commands
└── README.md          # This file
```

## Build Options

```bash
task build                          # Default (Debian Bookworm)
task build.debian DEBIAN_VERSION=bullseye  # Custom Debian version
```

## Extending the Base Image

If you need additional system packages:

```dockerfile
FROM hdae/ai-base
USER root
RUN apt-get update && apt-get install -y your-package
USER app
```
