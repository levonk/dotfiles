#!/usr/bin/env bash
# =====================================================================
# Dotfiles Test Runner
# Managed by chezmoi | https://github.com/levonk/dotfiles
#
# Purpose:
#   - Run all automated and static analysis tests for modular dotfiles.
#   - Ensures compliance, security, and maintainability.
#
# Usage:
#   ./bin/test-dotfiles.sh
#
# Requirements:
#   - bats (https://github.com/bats-core/bats-core)
#   - shellcheck (https://www.shellcheck.net/)
#
# Security: No sensitive data, safe for CI and local use.
# =====================================================================

set -euo pipefail

TEST_DIR="$(dirname "$0")/../private-deployment/dotfile-mgmt/internal-docs/requirements/test"
FEATURE_DIR="$(dirname "$0")/../private-deployment/dotfile-mgmt/internal-docs/requirements/gherkin/features"
PKG_ALIASES="$(dirname "$0")/../dot_config/shells/shared/pkg-aliases.sh"

# Source pkg-aliases.sh for cross-platform pkgadd
if [ -f "$PKG_ALIASES" ]; then
  # shellcheck source=/dev/null
  . "$PKG_ALIASES"
else
  echo "[ERROR] Could not find pkg-aliases.sh. Aborting install attempts."
fi

# Ensure shellcheck is installed
if ! command -v shellcheck >/dev/null 2>&1; then
  echo "[INFO] shellcheck not found. Attempting to install..."
  if command -v pkgadd >/dev/null 2>&1; then
    pkgadd shellcheck || echo "[ERROR] Failed to install shellcheck via pkgadd."
  else
    echo "[ERROR] No pkgadd alias found. Please install shellcheck manually."
  fi
fi

# Ensure bats is installed
if ! command -v bats >/dev/null 2>&1; then
  echo "[INFO] bats not found. Attempting to install..."
  if command -v pkgadd >/dev/null 2>&1; then
    pkgadd bats || pkgadd bats-core || echo "[ERROR] Failed to install bats/bats-core via pkgadd."
  else
    echo "[ERROR] No pkgadd alias found. Please install bats manually."
  fi
fi

# Run ShellCheck static analysis
if command -v shellcheck >/dev/null 2>&1; then
  echo "==> Running ShellCheck..."
  find "$(dirname "$0")/../dot_config/shells/shared" -type f -name '*.sh' -exec shellcheck --source-path=SCRIPTDIR --shell=bash {} +
else
  echo "[WARN] ShellCheck not found, skipping static analysis."
fi

# Run BATS tests
if command -v bats >/dev/null 2>&1; then
  echo "==> Running BATS tests..."
  bats "$TEST_DIR/dotfiles-modularization.bats"
else
  echo "[WARN] BATS not found, skipping functional tests."
fi

# Print location of BDD feature files
if [ -d "$FEATURE_DIR" ]; then
  echo "==> BDD feature scenarios are in: $FEATURE_DIR"
fi

exit 0
