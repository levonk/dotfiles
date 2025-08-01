# This file is managed by chezmoi (https://www.chezmoi.io/) and maintained at https://github.com/levonk/dotfiles

# =====================================================================
# Zsh Prompt Configuration
# =====================================================================

# First try to load Powerlevel10k
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
  P10K_LOADED=true
fi

# Source Powerlevel10k
if [[ -r ${XDG_CONFIG_HOME:-$HOME/.config}/zsh/plugins/powerlevel10k/powerlevel10k.zsh ]]; then
    source ${XDG_CONFIG_HOME:-$HOME/.config}/zsh/plugins/powerlevel10k/powerlevel10k.zsh
fi

# If Powerlevel10k isn't loaded, try Starship as a fallback
if [[ -z "$P10K_LOADED" ]] && command -v starship >/dev/null 2>&1; then
  eval "$(starship init zsh)"
fi

# =====================================================================
# End of Zsh Prompt Configuration
# =====================================================================
