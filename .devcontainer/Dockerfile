# Dotfiles Testing Environment
# Multi-stage build for optimized testing container
FROM ubuntu:22.04

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

# Install chezmoi
RUN sh -c "$(curl -fsLS get.chezmoi.io)" -- -b /usr/local/bin

# Create non-root user
ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=$USER_UID

RUN groupadd --gid $USER_GID $USERNAME \
    && useradd --uid $USER_UID --gid $USER_GID -m $USERNAME \
    && echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME

# Set up user environment
USER $USERNAME
WORKDIR /home/$USERNAME

# Create necessary directories
RUN mkdir -p \
    ~/.config/shells/shared/env \
    ~/.config/shells/zsh \
    ~/.config/shells/bash \
    ~/.config/git \
    ~/.local/bin \
    ~/.local/share/git

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
