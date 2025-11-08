#!/usr/bin/env zsh
# shellcheck shell=zsh
#{{- includeTemplate "dot_config/ai/templates/shell/sourceable.zsh.tmpl" (dict "path" .path "name" .name) -}}


# =====================================================================
#!/bin/bash
if [[ "" == "bash" ]]; then
  echo "ERROR: This script must be sourced, not executed."
  exit 1
fi
## Do not add a shebang so settings apply to your environment, not just this script

## Zsh-specific history configuration
## - Sources shared history settings, then applies zsh options

## Only apply for interactive zsh
if [ -z "${ZSH_VERSION:-}" ]; then
  return 0 2>/dev/null || exit 0
fi
case $- in
  *i*) :;;
  *) return 0 2>/dev/null || exit 0;;
esac

# Source shared history path setup
_shared_hist="${XDG_CONFIG_HOME:-$HOME/.config}/shells/shared/env/history.sh"
[ -r "$_shared_hist" ] && . "$_shared_hist"

# Zsh-specific history size persisted to file (respect existing if set)
export SAVEHIST="${SAVEHIST:-5000}"

# Zsh history behavior
setopt HIST_IGNORE_DUPS       # Don't record immediately repeated commands
setopt HIST_SAVE_NO_DUPS      # Remove older duplicates when saving
setopt HIST_IGNORE_ALL_DUPS   # Delete older command if duplicated
setopt HIST_FIND_NO_DUPS      # Do not display duplicates when searching history
setopt INC_APPEND_HISTORY     # Append commands to the history file immediately
# setopt SHARE_HISTORY          # Share history across all sessions
setopt EXTENDED_HISTORY 2>/dev/null || true
