#!/usr/bin/env sh
# shellcheck shell=sh
#{{- includeTemplate "dot_config/ai/snippets/shell/sourceable.sh.tmpl" (dict "path" .path "name" .name) -}}

# =====================================================================
# {{ .name | title }}
# Managed by chezmoi | https://github.com/levonk/dotfiles
# =====================================================================

# Ensure HOME is set
: "${HOME:=$(getent passwd "$USER" | cut -d: -f6)}"
: "${HOME:=$PWD}"

export HOME

# Original content follows:
# =====================================================================
: "${XDG_DATA_HOME:=$HOME/.local/share}"
: "${XDG_CONFIG_HOME:=$HOME/.config}"
: "${XDG_STATE_HOME:=$HOME/.local/state}"
: "${XDG_CACHE_HOME:=$HOME/.cache}"
: "${XDG_BIN_HOME:=$HOME/.local/bin}"

export XDG_DATA_HOME XDG_CONFIG_HOME XDG_STATE_HOME XDG_CACHE_HOME XDG_BIN_HOME
