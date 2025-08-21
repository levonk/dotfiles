#!/bin/bash
# This file is managed by chezmoi (https://www.chezmoi.io/) and maintained at https://github.com/levonk/dotfiles
# Shell prompt configuration

# Set up the prompt configuration
export PROMPT_CONFIG_DIR="${HOME}/.config/shells/prompt"

# Ensure the prompt config directory exists
if [ ! -d "${PROMPT_CONFIG_DIR}" ]; then
    mkdir -p "${PROMPT_CONFIG_DIR}"
fi

# Load prompt configuration based on the current shell
if [ -n "${BASH_VERSION}" ]; then
    # Bash prompt configuration
    export PS1='\[\e[1;34m\]\w\[\e[0m\] \[\e[1;32m\]\$\[\e[0m\] '
elif [ -n "${ZSH_VERSION}" ]; then
    # Zsh prompt configuration
    autoload -Uz vcs_info
    precmd() { vcs_info }
    zstyle ':vcs_info:git:*' formats '(%b)'
    setopt PROMPT_SUBST
    PROMPT='%F{blue}%~%f %F{green}${vcs_info_msg_0_}%f %# '
fi

# Add any custom prompt functions here
__prompt_command() {
    local exit_code=$?
    # Add any custom prompt commands here
    return $exit_code
}

# Set up the prompt command
if [ -n "${BASH_VERSION}" ]; then
    PROMPT_COMMAND="__prompt_command; ${PROMPT_COMMAND}"
elif [ -n "${ZSH_VERSION}" ]; then
    precmd_functions+=(__prompt_command)
fi
