#!/usr/bin/env sh
# shellcheck shell=sh
#{{- includeTemplate "dot_config/ai/snippets/shell/sourceable.sh.tmpl" (dict "path" .path "name" .name) -}}


# =====================================================================

#------------------------------------------------------------------------------
# Less Configuration
#------------------------------------------------------------------------------
export LESS="--RAW-CONTROL-CHARS --ignore-case --quit-at-eof --quit-if-one-screen --follow-name --HILITE-SEARCH --LONG-PROMPT --squeeze-blank-lines --tabs=4"
export LESSHISTFILE="${XDG_CACHE_HOME:-$HOME/.cache}/less/lesshst"
export LESSOPEN="| /usr/bin/lesspipe %s"
