#!/usr/bin/env zsh
# shellcheck shell=zsh
#{{- includeTemplate "dot_config/ai/snippets/shell/sourceable.zsh.tmpl" (dict "path" .path "name" .name) -}}


# =====================================================================
#!/bin/bash
if [[ "" == "bash" ]]; then
  echo "ERROR: This script must be sourced, not executed."
  exit 1
fi
# This file is managed by chezmoi (https://www.chezmoi.io/) and maintained at https://github.com/levonk/dotfiles
# Zsh-specific prompt configuration (fallback when fancy prompts are unavailable)

# Use vcs_info-based prompt as a lightweight fallback
autoload -Uz vcs_info
precmd() { vcs_info }
zstyle ':vcs_info:git:*' formats '(%b)'
setopt PROMPT_SUBST
PROMPT='%F{blue}%~%f %F{green}${vcs_info_msg_0_}%f %# '

# Optional custom prompt hook executed before each prompt
__prompt_command() {
  local exit_code=$?
  # Add any custom prompt commands here
  return $exit_code
}

# Register hook for zsh prompt lifecycle
precmd_functions+=(__prompt_command)
