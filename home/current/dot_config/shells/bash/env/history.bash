#!/usr/bin/env bash
# shellcheck shell=bash
#{{- includeTemplate "dot_config/ai/templates/shell/sourceable.bash.tmpl" (dict "path" .path "name" .name) -}}


# =====================================================================
# Bash-specific history configuration
# - Sources shared history settings, then applies bash options

# Only apply for interactive bash
case $- in
  *i*) :;;
  *) return 0 2>/dev/null || exit 0;;
esac

# Source shared history path setup
_shared_hist="${XDG_CONFIG_HOME:-$HOME/.config}/shells/shared/env/history.sh"
[ -r "$_shared_hist" ] && . "$_shared_hist"

# Bash history behavior
export HISTCONTROL="ignoredups:erasedups"
shopt -s histappend
# Optional timestamp format
export HISTTIMEFORMAT="${HISTTIMEFORMAT:-%F %T }"
