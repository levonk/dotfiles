#!/usr/bin/env sh
# shellcheck shell=sh
#{{- includeTemplate "dot_config/ai/templates/shell/sourceable.sh.tmpl" (dict "path" .path "name" .name) -}}

# =====================================================================

export PERLTIDY="${XDG_CONFIG_HOME:-$HOME/.config}"/perltidy/perltidyrc
