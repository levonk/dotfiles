#!/usr/bin/env zsh
# This file is managed by chezmoi (https://www.chezmoi.io/) and maintained at https://github.com/levonk/dotfiles

# =====================================================================
# Zsh Prompt Configuration
# =====================================================================

# Temporary path variables to avoid repetition (scoped by convention with __)
__CFG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"
__CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}"
__SHELLS_DIR="${__CFG_DIR}/shells"
__ZSH_DIR="${__SHELLS_DIR}/zsh"
__ZSH_PLUGINS_DIR="${__ZSH_DIR}/plugins"
__ZSH_PROMPTS_DIR="${__ZSH_DIR}/prompts"
__ZSH_UTIL_DIR="${__ZSH_DIR}/util"

# Optional prompt debug
if [[ -n "${DEBUG_PROMPT}" ]]; then
  echo "[prompt] Sourcing prompt.zsh (XDG_CONFIG_HOME=${XDG_CONFIG_HOME:-$HOME/.config})" >&2
fi

# First try to load Powerlevel10k
  # shellcheck disable=SC2296  # zsh-specific parameter expansion `(%):-%n`
  __INSTANT_PROMPT="${__CACHE_DIR}/p10k-instant-prompt-${(%):-%n}.zsh"
  if [[ -r "${__INSTANT_PROMPT}" ]]; then
    # shellcheck disable=SC1090  # Non-constant path; zsh caches instant prompt per user/shell
    source "${__INSTANT_PROMPT}"
    if [[ -n "${DEBUG_PROMPT}" ]]; then
      echo "[prompt] Loaded P10K instant prompt cache: ${__INSTANT_PROMPT}" >&2
    fi
  fi

  # Source Powerlevel10k (support both file names used by P10K)
  __POWERLEVEL10K_MAIN="${__ZSH_PLUGINS_DIR}/powerlevel10k/powerlevel10k.zsh"
  __POWERLEVEL10K_THEME="${__ZSH_PLUGINS_DIR}/powerlevel10k/powerlevel10k.zsh-theme"
  if [[ -r "${__POWERLEVEL10K_MAIN}" ]]; then
    # shellcheck disable=SC1091
    source "${__POWERLEVEL10K_MAIN}"
    P10K_LOADED=true
    if [[ -n "${DEBUG_PROMPT}" ]]; then
      echo "[prompt] Loaded P10K main: ${__POWERLEVEL10K_MAIN}" >&2
    fi
  elif [[ -r "${__POWERLEVEL10K_THEME}" ]]; then
    # shellcheck disable=SC1091
    source "${__POWERLEVEL10K_THEME}"
    P10K_LOADED=true
    if [[ -n "${DEBUG_PROMPT}" ]]; then
      echo "[prompt] Loaded P10K theme: ${__POWERLEVEL10K_THEME}" >&2
    fi
  fi

  # If Powerlevel10k isn't loaded, try Starship; otherwise use lightweight fallback
  if [[ -z "$P10K_LOADED" ]]; then
    __PROMPT_CFG="${__ZSH_UTIL_DIR}/prompt-cfg.zsh"
    if command -v starship >/dev/null 2>&1; then
      eval "$(starship init zsh)"
      export STARSHIP_LOADED=1
      if [[ -n "${DEBUG_PROMPT}" ]]; then
        echo "[prompt] Loaded Starship" >&2
      fi
    elif [[ -r "${__PROMPT_CFG}" ]]; then
      # shellcheck disable=SC1091
      source "${__PROMPT_CFG}"
      export FALLBACK_LOADED=1
      if [[ -n "${DEBUG_PROMPT}" ]]; then
        echo "[prompt] Loaded fallback prompt config: ${__PROMPT_CFG}" >&2
      fi
    fi
  fi

# =====================================================================
# End of Zsh Prompt Configuration
# =====================================================================

