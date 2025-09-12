#!/usr/bin/env zsh
# shellcheck shell=zsh
#{{- includeTemplate "dot_config/ai/templates/shell/sourceable.zsh.tmpl" (dict "path" .path "name" .name) -}}

function zle-keymap-select {
  case $KEYMAP in
    vicmd)  MODE="[N]" ;;
    viins)  MODE="[I]" ;;
    *)      MODE="[?]" ;;
  esac
  zle reset-prompt
}
zle -N zle-keymap-select
PROMPT='${MODE} %~ %# '
