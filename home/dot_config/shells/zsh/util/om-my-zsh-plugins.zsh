#!/usr/bin/env zsh
# This file is managed by chezmoi (https://www.chezmoi.io/) and maintained at https://github.com/levonk/dotfiles
#------------------------------------------------------------------------------
# OhMyZsh Plugin Manager
#------------------------------------------------------------------------------
# Temporary path variables to avoid repetition (scoped by convention with __)
__CFG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"
__ZSH_DIR="${__CFG_DIR}/shells/zsh"
__ZSH_PLUGINS_DIR="${__ZSH_DIR}/plugins"
__OHMYZSH_DIR="${__ZSH_DIR}/oh-my-zsh"

export ZSH="${__OHMYZSH_DIR}"
# Prefer Powerlevel10k if installed; otherwise fall back to robbyrussell
if [[ -d "${__ZSH_PLUGINS_DIR}/powerlevel10k" ]]; then
  # shellcheck disable=SC2034  # Used by oh-my-zsh when sourced
  ZSH_THEME="powerlevel10k/powerlevel10k"
  # Optional: skip first-run config wizard
  export POWERLEVEL9K_DISABLE_CONFIGURATION_WIZARD=true
else
  # shellcheck disable=SC2034  # Used by oh-my-zsh when sourced
  ZSH_THEME="robbyrussell"
fi
# shellcheck disable=SC2034  # Used by oh-my-zsh when sourced
plugins=(git)
if [[ -r "$ZSH/oh-my-zsh.sh" ]]; then
  # shellcheck disable=SC1091  # Non-constant path managed by chezmoi externals
  source "$ZSH/oh-my-zsh.sh"
fi

## Should be incorporated by `.chezmoiexternal.toml`
if [[ ! -d "${__ZSH_PLUGINS_DIR}/powerlevel10k" ]]; then
  echo "Installing Powerlevel10k..."
  git clone --depth=1 https://github.com/levonk/powerlevel10k.git "${__ZSH_PLUGINS_DIR}/powerlevel10k"
  # shellcheck disable=SC2016  # Intentionally keep parameter expansion literal in appended line
  echo 'source ${XDG_CONFIG_HOME:-$HOME/.config}/shells/zsh/plugins/powerlevel10k/powerlevel10k.zsh' >>! "${__ZSH_DIR}/prompts/prompt.zsh"
fi

