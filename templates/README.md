# Template Usage Guide

This template provides a ready-to-use Docker setup for Python applications using
the `hdae/ai-base` base image.

## What the Base Image Provides

| Feature                                   | Handled by                 |
| ----------------------------------------- | -------------------------- |
| UID/GID adjustment                        | `entrypoint.sh` (built-in) |
| Python installation (`uv python install`) | `entrypoint.sh` (built-in) |
| Virtual environment setup                 | `entrypoint.sh` (built-in) |
| Git repository cloning (if needed)        | **Your `start.sh`**        |
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

2. **Delete this README** (or rename it):

   This file is for template usage instructions only. Once you've copied the
   files, delete `README.md` from your project or replace it with your own.

3. **Edit `start.sh`** to customize for your project:

   - Clone repositories (if needed)
   - Install dependencies
   - Start your application

4. **Start**:

   ```bash
   task up
   # or: docker compose up
   ```

## Configuration

### Environment Variables

Set in `.env` or `docker-compose.yml`:

| Variable         | Default | Description               |
| ---------------- | ------- | ------------------------- |
| `PUID`           | 1000    | User ID inside container  |
| `PGID`           | 1000    | Group ID inside container |
| `PYTHON_VERSION` | 3.12    | Python version            |

### Git Repository Strategy

There are three recommended approaches for managing your project code:

#### 1. Volume Mount (Development)

Mount your local project directly for live code changes:

```yaml
# docker-compose.yml
services:
    app:
        volumes:
            - .:/workspace/app # Mount your project
            - app-data:/workspace
            - uv-cache:/workspace/.uv-cache
```

Best for active development with live code changes.

#### 2. Git Submodules

Add your project as a git submodule and mount it:

```bash
# In your docker-compose directory
git submodule add https://github.com/example/my-app.git app
git submodule update --init
```

Then mount in `docker-compose.yml`:

```yaml
volumes:
    - ./app:/workspace/app
```

Best for versioned dependencies and reproducible builds.

#### 3. Clone in start.sh (Plugins)

For plugins or dependencies that don't conflict with volume mounts, use the
`clone_or_update` helper function in `start.sh`:

```bash
# In start.sh
clone_or_update "https://github.com/example/plugin.git" "/workspace/plugins/example" "v1.0.0"
```

The helper function is idempotent and supports branches, tags, and commit
hashes. See `start.sh` for the complete function documentation and examples.

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
- Executing `/start.sh` (your script)

To fully customize the entrypoint, mount your own:

```yaml
volumes:
    - ./entrypoint.sh:/entrypoint.sh
```

## Debugging & Best Practices

### Recommended Workflow

When developing or debugging, run in **foreground mode** (without `-d`):

```bash
task up
# or: docker compose up
```

**Why?**

1. **Immediate Feedback**: You see logs and errors in real-time.
2. **No Restart Loops**: If `start.sh` fails, the container stops immediately,
   allowing you to read the specific error message.
3. **Simpler Troubleshooting**: Static logs make it easier to isolate errors and
   share them with AI assistants or colleagues.

**Avoid** using `task up.detach` (detached mode) for debugging, as it requires
extra steps to view logs (`task logs`) and can hide restart loops.

## Task Commands

```bash
task up                # Start container
task up.detach         # Start in background
task down              # Stop container
task restart           # Restart container
task exec              # Open bash shell
task exec -- <command> # Execute command
task logs              # View logs
task reset             # Delete app volume
```
