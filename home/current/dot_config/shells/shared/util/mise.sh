#!/usr/bin/env sh
# shellcheck shell=sh
#{{- includeTemplate "dot_config/ai/templates/shell/sourceable.sh.tmpl" (dict "path" .path "name" .name) -}}


# =====================================================================

# Shell-neutral mise wrapper and helpers
# This file provides a POSIX-safe `mise` function and fallbacks for paths.
# NOTE: PATH ordering is handled in env files (e.g., shared/env/mise-env.sh).

# Fallbacks for mise paths (no PATH mutation here; PATH managed in env)
: "${_MISE_BIN:=${HOME}/.local/bin/mise}"
: "${_MISE_SHIMS:=${XDG_DATA_HOME:-$HOME/.local/share}/mise/shims}"

# Helper: detect -h/--help among args (POSIX-safe)
_mise_contains_help() {
  for _a in "$@"; do
    [ "$_a" = "-h" ] || [ "$_a" = "--help" ] && return 0
  done
  return 1
}

# POSIX-safe wrapper that evals env-affecting subcommands
mise() {
  command="${1:-}"
  if [ "$#" = 0 ]; then
    command "$_MISE_BIN"
    return
  fi
  shift

  case "$command" in
    deactivate|shell|sh)
      if ! _mise_contains_help "$@"; then
        eval "$(command "$_MISE_BIN" "$command" "$@")"
        return $?
      fi
      ;;
  esac
  command "$_MISE_BIN" "$command" "$@"
}
