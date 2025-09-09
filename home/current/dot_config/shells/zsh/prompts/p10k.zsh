#!/usr/bin/env zsh
# shellcheck shell=zsh
#{{- includeTemplate "dot_config/ai/snippets/shell/sourceable.zsh.tmpl" (dict "path" .path "name" .name) -}}


# =====================================================================
#!/bin/bash
if [[ "" == "bash" ]]; then
  echo "ERROR: This script must be sourced, not executed."
  exit 1
fi
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
__ZSH_CUSTOM_DIR="${__ZSH_DIR}/custom"
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

  # Source Powerlevel10k from custom/themes first (official OMZ location), then plugins (legacy)
  __POWERLEVEL10K_MAIN="${__ZSH_PLUGINS_DIR}/powerlevel10k/powerlevel10k.zsh"
  __POWERLEVEL10K_THEME="${__ZSH_PLUGINS_DIR}/powerlevel10k/powerlevel10k.zsh-theme"
  __POWERLEVEL10K_MAIN_CUSTOM="${__ZSH_CUSTOM_DIR}/themes/powerlevel10k/powerlevel10k.zsh"
  __POWERLEVEL10K_THEME_CUSTOM="${__ZSH_CUSTOM_DIR}/themes/powerlevel10k/powerlevel10k.zsh-theme"

  if [[ -r "${__POWERLEVEL10K_MAIN_CUSTOM}" ]]; then
    # shellcheck disable=SC1091
    source "${__POWERLEVEL10K_MAIN_CUSTOM}"
    P10K_LOADED=true
    if [[ -n "${DEBUG_PROMPT}" ]]; then
      echo "[prompt] Loaded P10K main (custom): ${__POWERLEVEL10K_MAIN_CUSTOM}" >&2
    fi
  elif [[ -r "${__POWERLEVEL10K_THEME_CUSTOM}" ]]; then
    # shellcheck disable=SC1091
    source "${__POWERLEVEL10K_THEME_CUSTOM}"
    P10K_LOADED=true
    if [[ -n "${DEBUG_PROMPT}" ]]; then
      echo "[prompt] Loaded P10K theme (custom): ${__POWERLEVEL10K_THEME_CUSTOM}" >&2
    fi
  elif [[ -r "${__POWERLEVEL10K_MAIN}" ]]; then
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

  # If P10K was loaded, ensure its setup function is available and runs
  if [[ -n "$P10K_LOADED" ]]; then
    # Add potential theme directories to fpath for autoloaded functions
    typeset -a __P10K_FPATH_CANDIDATES
    __P10K_FPATH_CANDIDATES=()
    [[ -d "${__ZSH_CUSTOM_DIR}/themes/powerlevel10k" ]] && __P10K_FPATH_CANDIDATES+=("${__ZSH_CUSTOM_DIR}/themes/powerlevel10k")
    [[ -d "${__ZSH_PLUGINS_DIR}/powerlevel10k" ]] && __P10K_FPATH_CANDIDATES+=("${__ZSH_PLUGINS_DIR}/powerlevel10k")
    for __fp in "${__P10K_FPATH_CANDIDATES[@]}"; do
      if [[ -d "${__fp}" ]] && [[ ":$fpath:" != *":${__fp}:"* ]]; then
        fpath=("${__fp}" "${fpath[@]}")
        [[ -n "${DEBUG_PROMPT}" ]] && echo "[prompt] added to fpath: ${__fp}" >&2
      fi
    done

    # Attempt to autoload if the function file exists in fpath
    if [[ -z $(typeset -f prompt_powerlevel10k_setup 2>/dev/null) ]]; then
      autoload -Uz prompt_powerlevel10k_setup 2>/dev/null || true
      [[ -n "${DEBUG_PROMPT}" ]] && echo "[prompt] attempted autoload of prompt_powerlevel10k_setup" >&2
    fi

    if typeset -f prompt_powerlevel10k_setup >/dev/null 2>&1; then
      [[ -n "${DEBUG_PROMPT}" ]] && echo "[prompt] invoking prompt_powerlevel10k_setup" >&2
      prompt_powerlevel10k_setup
    else
      [[ -n "${DEBUG_PROMPT}" ]] && echo "[prompt] prompt_powerlevel10k_setup not found after initial source; attempting recovery" >&2
      # Recovery: attempt to source alternative entrypoints from theme dirs
      typeset -a __P10K_DIRS
      __P10K_DIRS=()
      [[ -d "${__ZSH_CUSTOM_DIR}/themes/powerlevel10k" ]] && __P10K_DIRS+=("${__ZSH_CUSTOM_DIR}/themes/powerlevel10k")
      [[ -d "${__ZSH_PLUGINS_DIR}/powerlevel10k" ]] && __P10K_DIRS+=("${__ZSH_PLUGINS_DIR}/powerlevel10k")
      for __dir in "${__P10K_DIRS[@]}"; do
        # Try common entry files first
        for __f in \
          "${__dir}/powerlevel10k.zsh" \
          "${__dir}/p10k.zsh" \
          "${__dir}/powerlevel10k.plugin.zsh"; do
          if [[ -r "${__f}" ]]; then
            [[ -n "${DEBUG_PROMPT}" ]] && echo "[prompt] recovery: sourcing: ${__f}" >&2
            # shellcheck disable=SC1090
            source "${__f}"
            if typeset -f prompt_powerlevel10k_setup >/dev/null 2>&1; then
              [[ -n "${DEBUG_PROMPT}" ]] && echo "[prompt] recovery: found prompt_powerlevel10k_setup via ${__f}" >&2
              break
            fi
          fi
        done
        if typeset -f prompt_powerlevel10k_setup >/dev/null 2>&1; then
          break
        fi
        # As a last resort, source all .zsh files in the directory (non-recursive) and common subdir
        for __glob in "${__dir}"/*.zsh "${__dir}/functions"/*.zsh; do
          [[ -r "${__glob}" ]] || continue
          [[ -n "${DEBUG_PROMPT}" ]] && echo "[prompt] recovery(all): sourcing: ${__glob}" >&2
          # shellcheck disable=SC1090
          source "${__glob}"
          if typeset -f prompt_powerlevel10k_setup >/dev/null 2>&1; then
            [[ -n "${DEBUG_PROMPT}" ]] && echo "[prompt] recovery(all): found prompt_powerlevel10k_setup via ${__glob}" >&2
            break
          fi
        done
        if typeset -f prompt_powerlevel10k_setup >/dev/null 2>&1; then
          break
        fi
      done
      if typeset -f prompt_powerlevel10k_setup >/dev/null 2>&1; then
        [[ -n "${DEBUG_PROMPT}" ]] && echo "[prompt] invoking prompt_powerlevel10k_setup (after recovery)" >&2
        prompt_powerlevel10k_setup
      else
        [[ -n "${DEBUG_PROMPT}" ]] && echo "[prompt] recovery failed: prompt_powerlevel10k_setup still missing" >&2
      fi
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
