#!/usr/bin/env sh
# shellcheck shell=sh
#{{- includeTemplate "dot_config/ai/snippets/shell/sourceable.sh.tmpl" (dict "path" .path "name" .name) -}}


# =====================================================================

export PYENV_ROOT="${XDG_DATA_HOME:-$HOME/.local/share}/pyenv"
PYENV_BIN="$PYENV_ROOT/bin"
PYENV_SHIMS="$PYENV_ROOT/shims"

if [ -x "$PYENV_BIN/pyenv" ]; then
  case ":$PATH:" in
    *":$PYENV_BIN:"*) ;;
    *) export PATH="$PYENV_BIN:$PATH" ;;
  esac
fi

if [ -d "$PYENV_SHIMS" ]; then
  case ":$PATH:" in
    *":$PYENV_SHIMS:"*) ;;
    *) export PATH="$PYENV_SHIMS:$PATH" ;;
  esac
fi

# Conditionally set shell completions if it's not already set correctly
if [ -z "${PYENV:-}" ] || [ ! -e "$PYENV" ]; then
  if [ -n "${ZSH_VERSION:-}" ]; then
    # We're in Zsh
    eval "$(pyenv init - zsh)"
  elif [ -n "${BASH_VERSION:-}" ]; then
    # We're in Bash
    eval "$(pyenv init - bash)"
  fi
fi
