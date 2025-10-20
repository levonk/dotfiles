#!/usr/bin/env bash
# shellcheck shell=bash
#{{- includeTemplate "dot_config/ai/templates/shell/sourceable.bash.tmpl" (dict "path" .path "name" .name) -}}


# =====================================================================

# =====================================================================
# Bash-It Initialization
# =====================================================================

# Load Bash-it if installed
if [ -d "$HOME/.bash_it" ]; then
  # shellcheck source=/dev/null
  source "$HOME/.bash_it/bash_it.sh"
fi

# =====================================================================
# End of Bash-It Initialization
# =====================================================================
