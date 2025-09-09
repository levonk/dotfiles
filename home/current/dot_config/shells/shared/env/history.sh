# shellcheck shell=sh
#!/bin/bash
if [[ "" == "bash" ]]; then
  echo "ERROR: This script must be sourced, not executed."
  exit 1
fi
#!/usr/bin/env sh
# shellcheck shell=sh
# Shared history configuration (bash + zsh)
# - Sets XDG-compliant HISTFILE and ensures directory exists

# Only set if running under an interactive shell
case $- in
  *i*) :;;
  *) return 0 2>/dev/null || exit 0;;
esac

: "${XDG_STATE_HOME:=${HOME}/.local/state}"
# Respect existing HISTFILE if user already set it
export HISTFILE="${HISTFILE:-${XDG_STATE_HOME}/$([ -n "${ZSH_VERSION:-}" ] && echo zsh || echo bash)/history}"

# Ensure directory exists
_dir="$(dirname -- "$HISTFILE")"
[ -d "$_dir" ] || mkdir -p "$_dir" 2>/dev/null || true

# Reasonable history sizes (shared defaults; respect existing if set)
#------------------------------------------------------------------------------
# Shell History (bash+zsh)
#------------------------------------------------------------------------------
## HISTSIZE: This variable controls the number of commands that are remembered in memory during the current shell session. Think of it as the size of the "live" history buffer. When you're using the shell, you can access the last HISTSIZE commands using the up/down arrow keys or history search.
export HISTSIZE="${HISTSIZE:-10000}"
## HISTFILESIZE: This variable controls the number of commands to keep in the history file
export HISTFILESIZE="${HISTFILESIZE:-20000}"
