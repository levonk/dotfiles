#!/usr/bin/env sh
# shellcheck shell=sh
#{{- includeTemplate "dot_config/ai/snippets/shell/sourceable.sh.tmpl" (dict "path" .path "name" .name) -}}


# =====================================================================

# This file is managed by chezmoi (https://www.chezmoi.io/) and maintained at https://github.com/levonk/dotfiles
export MYSQL_PROMPT="\\\\[\\\\033[32m\\\\]\\u@\\h:\\d> \\\\[\\\\033[0m\\\\]"
