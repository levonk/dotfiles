#!/usr/bin/env bash
# shellcheck shell=bash
#{{- includeTemplate "dot_config/ai/templates/shell/sourceable.sh.tmpl" (dict "path" .path "name" .name) -}}

# =====================================================================

# Bash-specific ctags integration
# This script hooks the `auto_ctags` function (defined in shared/util/auto-ctags.sh)
# into the Bash prompt command. This causes it to run every time a new prompt is displayed.

# Prepend auto_ctags to the existing PROMPT_COMMAND to avoid overwriting it.
export PROMPT_COMMAND="auto_ctags;${PROMPT_COMMAND:-}"
