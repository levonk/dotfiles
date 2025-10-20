#!/usr/bin/env sh
# shellcheck shell=sh
#{{- includeTemplate "dot_config/ai/templates/shell/sourceable.sh.tmpl" (dict "path" .path "name" .name) -}}


# =====================================================================

# This file is managed by chezmoi (https://www.chezmoi.io/) and maintained at https://github.com/levonk/dotfiles
# Shell keybindings (from sharedrc)
# Note: Only effective in shells that support bindkey (zsh)

#------------------------------------------------------------------------------
# Wrapper: Only act in zsh; no-op for bash/others
#------------------------------------------------------------------------------
if [ -z "${ZSH_VERSION:-}" ]; then
  # Not zsh; this shared module should not apply
  return 0 2>/dev/null || exit 0
fi

# In zsh: delegate to zsh-specific keybinds to avoid duplication
_ZSH_KEYBINDS_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/shells/zsh/util/keybinds.zsh"
if [ -r "$_ZSH_KEYBINDS_FILE" ]; then
  . "$_ZSH_KEYBINDS_FILE"
else
  # Fallback (very minimal) to avoid completely missing basics if file not found
  autoload -U up-line-or-beginning-search down-line-or-beginning-search
  zle -N up-line-or-beginning-search
  zle -N down-line-or-beginning-search
  bindkey "^[[A" up-line-or-beginning-search
  bindkey "^[[B" down-line-or-beginning-search
  bindkey '^A' beginning-of-line
  bindkey '^E' end-of-line
fi
