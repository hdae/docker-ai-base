# Template Usage Guide

This template provides a ready-to-use Docker setup for Python applications using
the `hdae/ai-base` base image.

## What the Base Image Provides

| Feature                                   | Handled by                 |
| ----------------------------------------- | -------------------------- |
| UID/GID adjustment                        | `entrypoint.sh` (built-in) |
| Python installation (`uv python install`) | `entrypoint.sh` (built-in) |
| Virtual environment setup                 | `entrypoint.sh` (built-in) |
| vcstool repository import                 | `entrypoint.sh` (built-in) |
| Dependency installation                   | **Your `start.sh`**        |
| Application startup                       | **Your `start.sh`**        |

## Prerequisites

- Docker and Docker Compose installed
- `hdae/ai-base` image built (see main project README)
- [Task](https://taskfile.dev/) (optional)

## Setup

1. **Copy template files** to your project:
   ```bash
   cp -r templates/* /path/to/your-project/
   ```

2. **Edit `start.sh`** to customize for your project:
   - Install dependencies
   - Start your application

3. **Start**:
   ```bash
   task up
   # or: docker-compose up
   ```

## Configuration

### Environment Variables

Set in `.env` or `docker-compose.yml`:

| Variable         | Default | Description                               |
| ---------------- | ------- | ----------------------------------------- |
| `PUID`           | 1000    | User ID inside container                  |
| `PGID`           | 1000    | Group ID inside container                 |
| `PYTHON_VERSION` | 3.12    | Python version                            |
| `SKIP_VCS`       | false   | Skip vcstool installation and repo import |

### Development Mode (without app.repos.yaml)

For local development where you mount your project directly, you don't need
`app.repos.yaml`:

1. **Remove or comment out** the `app.repos.yaml` volume mount in
   `docker-compose.yml`
2. **Mount your project** to `/workspace/app`
3. **Set `SKIP_VCS=true`** to skip vcstool installation and repository import

```yaml
# docker-compose.yml
services:
    app:
        image: hdae/ai-base
        environment:
            - PUID=${PUID:-1000}
            - PGID=${PGID:-1000}
            - PYTHON_VERSION=3.12
            - SKIP_VCS=true # Skip vcs import
        volumes:
            - .:/workspace/app # Mount your project
            - app-data:/workspace
            - uv-cache:/workspace/.uv-cache
            # - ./app.repos.yaml:/workspace/app.repos.yaml  # Not needed
```

This pattern is recommended when:

- You're actively developing and want live code changes
- Your project already exists locally
- You don't need to clone external repositories

### GPU Support

Uncomment in `docker-compose.yml`:

```yaml
deploy:
    resources:
        reservations:
            devices:
                - driver: nvidia
                  count: 1
                  capabilities: [gpu]
```

### Custom Dockerfile

If you need additional system packages, create a `Dockerfile` extending
`hdae/ai-base`:

```dockerfile
FROM hdae/ai-base

USER root
RUN apt-get update && apt-get install -y --no-install-recommends \
    your-package \
    && rm -rf /var/lib/apt/lists/*
# Note: Do NOT add "USER app" here.
# The entrypoint runs as root and switches to app user via gosu.
```

Then update `docker-compose.yml`:

```yaml
services:
    app:
        build: .
        # image: hdae/ai-base  # Comment this out
```

### Custom Entrypoint

The base image's `entrypoint.sh` handles:

- UID/GID adjustment (runs as root, then switches to `app` user)
- Python installation via `uv`
- Virtual environment setup at `/workspace/.venv`
- vcstool repository import (if `app.repos.yaml` exists)
- Executing `/start.sh` (your script)

To fully customize the entrypoint, mount your own:

```yaml
volumes:
    - ./entrypoint.sh:/entrypoint.sh
```

## Task Commands

```bash
task up         # Start container
task up.detach  # Start in background
task down       # Stop container
task shell      # Open bash in container
task logs       # View logs
task reset      # Delete app volume
```
