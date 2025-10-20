#!/usr/bin/env sh
# shellcheck shell=sh
#{{- includeTemplate "dot_config/ai/templates/shell/sourceable.sh.tmpl" (dict "path" .path "name" .name) -}}


# =====================================================================

export NPM_CONFIG_USERCONFIG="${XDG_CONFIG_HOME:-$HOME/.config}"/npm/npmrc
