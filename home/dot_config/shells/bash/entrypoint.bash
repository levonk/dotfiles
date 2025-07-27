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

# Source all configuration files in the correct order
for dir in env util aliases completions; do
  for config_file in "${XDG_CONFIG_HOME:-$HOME/.config}/shells/bash/${dir}/"*; do
    if [ -r "$config_file" ] && [ -f "$config_file" ]; then
      # shellcheck source=/dev/null
      . "$config_file"
    fi
  done
done

# Source universal sharedrc (shell-neutral)
if [ -r "${XDG_CONFIG_HOME:-$HOME/.config}/shells/shared/sharedrc" ]; then
  # shellcheck source=/dev/null
  source "${XDG_CONFIG_HOME:-$HOME/.config}/shells/shared/sharedrc"
fi

# Export for compliance and test detection
export DOTFILES_BASH_SHARED_LOADED=1
