#!/usr/bin/env sh
# shellcheck shell=sh
#{{- includeTemplate "dot_config/ai/snippets/shell/sourceable.sh.tmpl" (dict "path" .path "name" .name) -}}


# =====================================================================

export SDKMAN_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"/sdkman
