#!/usr/bin/env sh
# shellcheck shell=sh
#{{- includeTemplate "dot_config/ai/snippets/shell/sourceable.sh.tmpl" (dict "path" .path "name" .name) -}}


# =====================================================================

#!/usr/bin/env bash
# This file is managed by chezmoi (https://www.chezmoi.io/) and maintained at https://github.com/levonk/dotfiles
# Shell prompt configuration

# Set up the prompt configuration
export PROMPT_CONFIG_DIR="${HOME}/.config/shells/prompt"

# Ensure the prompt config directory exists
if [ ! -d "${PROMPT_CONFIG_DIR}" ]; then
    mkdir -p "${PROMPT_CONFIG_DIR}"
fi

# Only proceed for Bash; no-ops for other shells
if [ -z "${BASH_VERSION:-}" ]; then
    return 0 2>/dev/null || exit 0
fi

# Bash prompt configuration
export PS1='\[\e[1;34m\]\w\[\e[0m\] \[\e[1;32m\]\$\[\e[0m\] '

# Add any custom prompt functions here
__prompt_command() {
    local exit_code=$?
    # Add any custom prompt commands here
    return $exit_code
}

# Set up the prompt command (Bash)
PROMPT_COMMAND="__prompt_command; ${PROMPT_COMMAND}"
