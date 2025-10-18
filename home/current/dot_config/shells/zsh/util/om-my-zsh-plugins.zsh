#!/usr/bin/env zsh
# shellcheck shell=zsh
#{{- includeTemplate "dot_config/ai/templates/shell/sourceable.zsh.tmpl" (dict "path" .path "name" .name) -}}


# =====================================================================
#!/bin/bash
if [[ "" == "bash" ]]; then
  echo "ERROR: This script must be sourced, not executed."
  exit 1
fi
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
__ZSH_CUSTOM_DIR="${__ZSH_DIR}/custom"

export ZSH="${__OHMYZSH_DIR}"
export ZSH_CUSTOM="${__ZSH_CUSTOM_DIR}"

# Debug: entering OMZ plugin manager
if [[ "${DEBUG_MODULE_LOADING:-0}" == "1" ]]; then
  print -u2 -- "[DEBUG] Entering module: OMZ plugin manager ($0)"
  print -u2 -- "[DEBUG] ZSH dir: ${ZSH}, ZSH_CUSTOM: ${ZSH_CUSTOM}"
fi

# Ensure OMZ custom dirs exist
mkdir -p "${ZSH_CUSTOM}/themes" 2>/dev/null || true

# Prefer Powerlevel10k under OMZ's expected theme location
P10K_OMZ_THEME_FILE="${ZSH_CUSTOM}/themes/powerlevel10k/powerlevel10k.zsh-theme"
__set_theme() {
  # ensure global in zsh even when sourced within a function
  if command -v typeset >/dev/null 2>&1 && typeset -g __tmp 2>/dev/null; then
    # typeset -g supported
    typeset -g ZSH_THEME="$1"
  else
    ZSH_THEME="$1"
  fi
  export ZSH_THEME  # harmless for OMZ; ensures visibility
}

[[ "${DEBUG_MODULE_LOADING:-0}" == "1" ]] && print -u2 -- "[DEBUG] Evaluating P10K theme path: ${P10K_OMZ_THEME_FILE}"
if [[ -r "${P10K_OMZ_THEME_FILE}" ]]; then
  __set_theme "powerlevel10k/powerlevel10k"
  export POWERLEVEL9K_DISABLE_CONFIGURATION_WIZARD=true
  [[ "${DEBUG_MODULE_LOADING:-0}" == "1" ]] && print -u2 -- "[DEBUG] Selected theme: ${ZSH_THEME} (via custom path)"
else
  __set_theme "robbyrussell"
  [[ -n "${DEBUG_PROMPT:-}" ]] && echo "[omz] P10K theme not found under $ZSH_CUSTOM/themes; using fallback: ${ZSH_THEME}" >&2
  [[ "${DEBUG_MODULE_LOADING:-0}" == "1" ]] && print -u2 -- "[DEBUG] P10K theme not found; fallback theme: ${ZSH_THEME}"
fi
[[ -n "${DEBUG_PROMPT:-}" ]] && echo "[omz] Final ZSH_THEME before OMZ: '${ZSH_THEME}'" >&2
plugins=()
if [[ -r "$ZSH/oh-my-zsh.sh" ]]; then
  # shellcheck disable=SC1091  # Non-constant path managed by chezmoi externals
  [[ "${DEBUG_MODULE_LOADING:-0}" == "1" ]] && print -u2 -- "[DEBUG] Attempting to load module: oh-my-zsh ($ZSH/oh-my-zsh.sh)"
  source "$ZSH/oh-my-zsh.sh"
  [[ "${DEBUG_MODULE_LOADING:-0}" == "1" ]] && print -u2 -- "[DEBUG] Successfully loaded module: oh-my-zsh"
else
  [[ "${DEBUG_MODULE_LOADING:-0}" == "1" ]] && print -u2 -- "[DEBUG] Skipping module (not readable): oh-my-zsh ($ZSH/oh-my-zsh.sh)"
fi

# If OMZ didn't actually load P10K for any reason, ensure it's initialized
if [[ "${ZSH_THEME:-}" == "powerlevel10k/powerlevel10k" ]]; then
  if ! typeset -f prompt_powerlevel10k_setup >/dev/null 2>&1; then
    P10K_THEME_FILE="${__ZSH_PLUGINS_DIR}/powerlevel10k/powerlevel10k.zsh-theme"
    P10K_THEME_FILE_CUSTOM="${ZSH_CUSTOM}/themes/powerlevel10k/powerlevel10k.zsh-theme"
    if [[ -r "$P10K_THEME_FILE" ]]; then
      [[ -n "${DEBUG_PROMPT:-}" ]] && echo "[omz] sourcing P10K theme directly (plugins): $P10K_THEME_FILE" >&2
      # shellcheck disable=SC1091
      [[ "${DEBUG_MODULE_LOADING:-0}" == "1" ]] && print -u2 -- "[DEBUG] Attempting to load module: p10k theme (plugins) ($P10K_THEME_FILE)"
      source "$P10K_THEME_FILE"
      [[ "${DEBUG_MODULE_LOADING:-0}" == "1" ]] && print -u2 -- "[DEBUG] Successfully loaded module: p10k theme (plugins)"
    elif [[ -r "$P10K_THEME_FILE_CUSTOM" ]]; then
      [[ -n "${DEBUG_PROMPT:-}" ]] && echo "[omz] sourcing P10K theme directly (custom): $P10K_THEME_FILE_CUSTOM" >&2
      # shellcheck disable=SC1091
      [[ "${DEBUG_MODULE_LOADING:-0}" == "1" ]] && print -u2 -- "[DEBUG] Attempting to load module: p10k theme (custom) ($P10K_THEME_FILE_CUSTOM)"
      source "$P10K_THEME_FILE_CUSTOM"
      [[ "${DEBUG_MODULE_LOADING:-0}" == "1" ]] && print -u2 -- "[DEBUG] Successfully loaded module: p10k theme (custom)"
    else
      [[ -n "${DEBUG_PROMPT:-}" ]] && echo "[omz] P10K theme missing in both plugins and custom paths" >&2
      [[ -n "${DEBUG_MODULE_LOADING:-}" ]] && print -u2 -- "[DEBUG] P10K theme not found in plugins or custom paths"
    fi
  fi
  # Load user p10k config if present
  if [[ -r "${HOME}/.p10k.zsh" ]]; then
    [[ -n "${DEBUG_PROMPT:-}" ]] && echo "[omz] sourcing user p10k config: ${HOME}/.p10k.zsh" >&2
    # shellcheck disable=SC1090
    [[ -n "${DEBUG_MODULE_LOADING:-}" ]] && print -u2 -- "[DEBUG] Attempting to load module: user p10k config (${HOME}/.p10k.zsh)"
    source "${HOME}/.p10k.zsh"
    [[ -n "${DEBUG_MODULE_LOADING:-}" ]] && print -u2 -- "[DEBUG] Successfully loaded module: user p10k config"
  fi
fi
# Debug: end-of-file marker
if [[ "${DEBUG_MODULE_LOADING:-0}" == "1" ]]; then
  print -u2 -- "[DEBUG] Completed OMZ plugin manager initialization"
fi
