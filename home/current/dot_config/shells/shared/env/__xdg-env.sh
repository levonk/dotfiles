#!/usr/bin/env sh
# shellcheck shell=sh
#{{- includeTemplate "dot_config/ai/templates/shell/sourceable.sh.tmpl" (dict "path" .path "name" .name) -}}

# =====================================================================
# {{ .name | title }}
# Managed by chezmoi | https://github.com/levonk/dotfiles
# =====================================================================

# Ensure HOME is set without invoking any network or NSS lookups
# Avoid using getent here; this file can be sourced from ~/.zshenv very early
# where any blocking lookup can freeze the login shell.
if [ -z "${HOME:-}" ]; then
  if [ -n "${USER:-}" ] && [ -d "/home/${USER}" ]; then
    HOME="/home/${USER}"
  else
    HOME="${PWD:-/tmp}"
  fi
fi

export HOME

# Original content follows:
# =====================================================================
: "${XDG_DATA_HOME:=$HOME/.local/share}"
: "${XDG_CONFIG_HOME:=$HOME/.config}"
: "${XDG_STATE_HOME:=$HOME/.local/state}"
: "${XDG_CACHE_HOME:=$HOME/.cache}"
: "${XDG_BIN_HOME:=$HOME/.local/bin}"

export XDG_DATA_HOME XDG_CONFIG_HOME XDG_STATE_HOME XDG_CACHE_HOME XDG_BIN_HOME
