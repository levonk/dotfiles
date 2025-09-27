# ==============================================================================
# STAGE 1: Base Image with Tools
# ==============================================================================
# Configurable base image; default to Google's Docker Hub mirror to avoid 401/rate limits
ARG BASE_IMAGE=mirror.gcr.io/library/debian:bookworm-slim
FROM ${BASE_IMAGE} AS dotfiles-base

# Avoid prompts from apt
ENV DEBIAN_FRONTEND=noninteractive

# Install system dependencies
RUN apt-get update && apt-get install -y \
    # Core utilities
    curl \
    wget \
    git \
    vim \
    nano \
    sudo \
    # Shell environments
    bash \
    zsh \
    # Testing framework
    bats \
    jq \
    # Development tools
    build-essential \
    # Chezmoi dependencies
    ca-certificates \
    gnupg \
    # Performance monitoring
    time \
    htop \
    # Network tools for git operations
    openssh-client \
    # Clean up
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Helper for runtime package installs by scripts (ensures update is run)
RUN printf '#!/usr/bin/env bash\nset -euo pipefail\nsudo apt-get update\nsudo apt-get install -y --no-install-recommends "$@"\n' \
      > /usr/local/bin/apt-install \
    && chmod +x /usr/local/bin/apt-install

# Install chezmoi
RUN sh -c "$(curl -fsLS get.chezmoi.io)" -- -b /usr/local/bin

# ==============================================================================
# STAGE 2: User Environment Layer
# ==============================================================================
FROM dotfiles-base AS dotfiles-test-env

# Create non-root user
ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=$USER_UID

RUN groupadd --gid $USER_GID $USERNAME \
    && useradd --uid $USER_UID --gid $USER_GID -m $USERNAME \
    && echo $USERNAME ALL=\(ALL\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME

# Set up user environment
USER $USERNAME
WORKDIR /home/$USERNAME

# Set default shell to zsh
RUN sudo chsh -s /bin/zsh $USERNAME

# Environment variables for testing
ENV DOTFILES_TEST_MODE=true
ENV DEBUG_MODULE_LOADING=1
ENV SHELL=/bin/zsh
ENV HOME=/home/$USERNAME

# Set working directory to workspace
WORKDIR /workspace

# Default command
CMD ["/bin/zsh"]
