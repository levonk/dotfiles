#!/usr/bin/env bash
# =====================================================================
# DevContainer Setup Script for Dotfiles Testing
# Managed by chezmoi | https://github.com/levonk/dotfiles
#
# Purpose:
#   - Initialize the development container for dotfiles testing
#   - Set up test environment and dependencies
#   - Configure shell environments for testing
# =====================================================================

set -euo pipefail

# Variables for DRY principle
WORKSPACE_DIR="/workspace"
HOME_CONFIG_DIR="$HOME/.config"
SHELLS_CONFIG_DIR="$HOME_CONFIG_DIR/shells"
GIT_CONFIG_DIR="$HOME_CONFIG_DIR/git"
DOTFILES_HOME_DIR="$WORKSPACE_DIR/home"

echo "🚀 Setting up dotfiles testing environment..."

# Create necessary directories
echo "📁 Creating configuration directories..."
mkdir -p "$SHELLS_CONFIG_DIR"/{shared/{env,util},zsh,bash}
mkdir -p "$GIT_CONFIG_DIR"
mkdir -p "$HOME/.local"/{bin,share/git}

# Copy essential configuration files for testing
echo "📋 Copying dotfiles configuration..."
if [ -d "$DOTFILES_HOME_DIR" ]; then
    # Copy shell configurations
    if [ -d "$DOTFILES_HOME_DIR/dot_config/shells" ]; then
        cp -r "$DOTFILES_HOME_DIR/dot_config/shells/"* "$SHELLS_CONFIG_DIR/" 2>/dev/null || true
    fi

    # Copy git configurations
    if [ -d "$DOTFILES_HOME_DIR/dot_config/git" ]; then
        cp -r "$DOTFILES_HOME_DIR/dot_config/git/"* "$GIT_CONFIG_DIR/" 2>/dev/null || true
    fi

    # Copy local bin scripts
    if [ -d "$DOTFILES_HOME_DIR/dot_local/bin" ]; then
        cp -r "$DOTFILES_HOME_DIR/dot_local/bin/"* "$HOME/.local/bin/" 2>/dev/null || true
        chmod +x "$HOME/.local/bin/"* 2>/dev/null || true
    fi

    # Copy local share data
    if [ -d "$DOTFILES_HOME_DIR/dot_local/share" ]; then
        cp -r "$DOTFILES_HOME_DIR/dot_local/share/"* "$HOME/.local/share/" 2>/dev/null || true
    fi
else
    echo "⚠️  Warning: $DOTFILES_HOME_DIR not found, skipping configuration copy"
fi

# Set up PATH
echo "🔧 Configuring environment..."
export PATH="$HOME/.local/bin:$PATH"

# Create a minimal test configuration
echo "🧪 Creating test configuration..."
cat > "$HOME/.zshrc" << 'EOF'
# Test zshrc for devcontainer
export DOTFILES_TEST_MODE=true
export DEBUG_MODULE_LOADING=1

# Add local bin to PATH
export PATH="$HOME/.local/bin:$PATH"

# Source shared configuration if available
if [ -f "$HOME/.config/shells/shared/entrypointrc.sh" ]; then
    source "$HOME/.config/shells/shared/entrypointrc.sh"
elif [ -f "$HOME/.config/shells/shared/sharedrc.sh" ]; then
    source "$HOME/.config/shells/shared/sharedrc.sh"
fi

echo "✅ Dotfiles test environment loaded"
EOF

cat > "$HOME/.bashrc" << 'EOF'
# Test bashrc for devcontainer
export DOTFILES_TEST_MODE=true
export DEBUG_MODULE_LOADING=1

# Add local bin to PATH
export PATH="$HOME/.local/bin:$PATH"

# Source shared configuration if available
if [ -f "$HOME/.config/shells/shared/entrypointrc.sh" ]; then
    source "$HOME/.config/shells/shared/entrypointrc.sh"
elif [ -f "$HOME/.config/shells/shared/sharedrc.sh" ]; then
    source "$HOME/.config/shells/shared/sharedrc.sh"
fi

echo "✅ Dotfiles test environment loaded"
EOF

# Verify bats installation
echo "🧪 Verifying test framework..."
if command -v bats >/dev/null 2>&1; then
    echo "✅ Bats testing framework is available"
    bats --version
else
    echo "❌ Bats testing framework not found"
    exit 1
fi

# Test basic shell functionality
echo "🔍 Testing basic shell functionality..."
if [ -f "$SHELLS_CONFIG_DIR/shared/util/platform-detection.sh" ]; then
    echo "✅ Platform detection utility found"
else
    echo "⚠️  Platform detection utility not found"
fi

if [ -f "$SHELLS_CONFIG_DIR/shared/util/shell-availability.sh" ]; then
    echo "✅ Shell availability utility found"
else
    echo "⚠️  Shell availability utility not found"
fi

echo "🎉 DevContainer setup completed successfully!"
echo ""
echo "Available commands:"
echo "  - Run tests: bats scripts/tests/shell-tests.bats"
echo "  - Debug mode: DEBUG_MODULE_LOADING=1 zsh"
echo "  - Performance test: .devcontainer/test.sh"
echo ""
