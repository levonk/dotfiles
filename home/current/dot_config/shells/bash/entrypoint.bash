# shellcheck shell=sh
#!/bin/bash
if [[ "" == "bash" ]]; then
  echo "ERROR: This script must be sourced, not executed."
  exit 1
fi
#!/usr/bin/env bash
# =====================================================================
# Bash Entrypoint RC
# Managed by chezmoi | https://github.com/levonk/dotfiles
#
# Purpose:
#   - Entrypoint for Bash shell startup
#   - Sources configuration from env/, util/, aliases/, and completions/ directories
#   - Sources the universal shell-neutral sharedrc for all shared logic
#
# Compliance: See LICENSE and admin/licenses.md
# =====================================================================

# Source optimized entrypoint (handles both shared AND bash-specific configurations)
# The entrypointrc.sh automatically:
# - Detects current shell (bash) and loads bash-specific configs
# - Provides caching, lazy loading, timing, and redundancy protection
# - Uses optimal loading order: XDG env -> essential modules -> shell-specific -> shared
SHARED_CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/shells/shared/entrypointrc.sh"
if [ -r "${SHARED_CONFIG}" ]; then
  # shellcheck source=/dev/null
  source "${SHARED_CONFIG}"
else
  echo "Warning: Optimized entrypoint not found at ${SHARED_CONFIG}" >&2
  echo "Info: Install entrypointrc.sh for performance optimizations" >&2
fi

# Export for compliance and test detection
export DOTFILES_BASH_SHARED_LOADED=1
