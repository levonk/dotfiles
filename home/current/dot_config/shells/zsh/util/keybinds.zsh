# shellcheck shell=sh
#!/bin/bash
if [[ "" == "bash" ]]; then
  echo "ERROR: This script must be sourced, not executed."
  exit 1
fi
# This file is managed by chezmoi (https://www.chezmoi.io/) and maintained at https://github.com/levonk/dotfiles
# =====================================================================
# Zsh Keybinds Management
# =====================================================================

# History Search Keybindings
# Ensure widgets are available
autoload -U up-line-or-beginning-search down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search

# Arrow keys for history-beginning search (both insert and vi cmd modes)
bindkey "$terminfo[kcuu1]" up-line-or-beginning-search         # Up Arrow
bindkey -a "$terminfo[kcuu1]" up-line-or-beginning-search      # Up in vicmd
bindkey "$terminfo[kcud1]" down-line-or-beginning-search       # Down Arrow
bindkey -a "$terminfo[kcud1]" down-line-or-beginning-search    # Down in vicmd

# Reverse incremental search
bindkey '^R' history-incremental-search-backward
bindkey -a '^R' history-incremental-search-backward

# Alt+p for history substring search backward
bindkey "\e[p" history-beginning-search-backward
bindkey -a "\e[p" history-beginning-search-backward
# Alt+n for history substring search forward
bindkey "\e[n" history-beginning-search-forward
bindkey -a "\e[n" history-beginning-search-forward

# Prompt editing
bindkey '^a' beginning-of-line
bindkey '^e' end-of-line

# Source completion (autocomplete)
zstyle ':completion:*' menu select

# =====================================================================
# End of Powerlevel10k Configuration
# =====================================================================
