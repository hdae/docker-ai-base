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
RUN groupadd -g 1000 app && \
    useradd -m -u 1000 -g app -s /bin/bash app

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
