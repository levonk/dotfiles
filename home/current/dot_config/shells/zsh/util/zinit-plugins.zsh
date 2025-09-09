# shellcheck shell=sh
#!/bin/bash
if [[ "" == "bash" ]]; then
  echo "ERROR: This script must be sourced, not executed."
  exit 1
fi
# This file is managed by chezmoi (https://www.chezmoi.io/) and maintained at https://github.com/levonk/dotfiles

## =====================================================================
## Zinit Plugin Management - But we're using oh-my-zsh
## =====================================================================
#
## Load Zinit if installed
#if [[ -f "${HOME}/.zinit/bin/zinit.zsh" ]]; then
#  # shellcheck source=/dev/null
#  source "${HOME}/.zinit/bin/zinit.zsh"
#  autoload -Uz _zinit
#  (( ${+_comps} )) && _comps[zinit]=_zinit
#fi
#
## =====================================================================
## End of Zinit Plugin Management
## =====================================================================

