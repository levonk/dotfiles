#!/usr/bin/env sh
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
export HISTSIZE="${HISTSIZE:-10000}"
export HISTFILESIZE="${HISTFILESIZE:-20000}"
