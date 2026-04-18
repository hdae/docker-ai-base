# ========================================
# Global ARGs (must be before all FROM statements)
# ========================================
ARG UV_VERSION=0.9.17
ARG DEBIAN_VERSION=bookworm

# ========================================
# UV Stage (for variable expansion workaround)
# ========================================
FROM ghcr.io/astral-sh/uv:${UV_VERSION} AS uv

# ========================================
# Base Image
# ========================================
FROM debian:${DEBIAN_VERSION}-slim

LABEL maintainer="hdae"
LABEL org.opencontainers.image.description="Minimal Python/AI base image with uv"

# ========================================
# Install uv
# ========================================
COPY --from=uv /uv /usr/local/bin/uv
COPY --from=uv /uvx /usr/local/bin/uvx

# ========================================
# System Dependencies
# ========================================
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    curl \
    ca-certificates \
    gosu \
    && rm -rf /var/lib/apt/lists/*

# ========================================
# User Setup (Default UID/GID, adjusted at runtime)
# ========================================
# Guard against GID/UID 1000 already existing in the base image.
RUN if ! getent group 1000 >/dev/null; then groupadd -g 1000 app; else groupmod -n app "$(getent group 1000 | cut -d: -f1)"; fi && \
    if ! getent passwd 1000 >/dev/null; then useradd -m -u 1000 -g app -s /bin/bash app; else usermod -l app -d /home/app -m -g app -s /bin/bash "$(getent passwd 1000 | cut -d: -f1)"; fi

# ========================================
# Working Directory
# ========================================
WORKDIR /workspace

# ========================================
# Entrypoint
# ========================================
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["bash"]
