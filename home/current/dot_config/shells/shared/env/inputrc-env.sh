#!/usr/bin/env sh
# shellcheck shell=sh
#{{- includeTemplate "dot_config/ai/snippets/shell/sourceable.sh.tmpl" (dict "path" .path "name" .name) -}}


# =====================================================================

export INPUTRC=${XDG_CONFIG_HOME:-$HOME/.config}/inputrc/inputrc.conf
