# This file is managed by chezmoi (https://www.chezmoi.io/) and maintained at https://github.com/levonk/dotfiles
# Shell keybindings (from sharedrc)
# Note: Only effective in shells that support bindkey (zsh)

#------------------------------------------------------------------------------
# History Search Keybindings
#------------------------------------------------------------------------------
bindkey    '^[p' history-beginning-search-backward # '^B'
bindkey -a '^[p' history-beginning-search-backward # '^B'
bindkey    '^[n' history-beginning-search-forward  # '^F'
bindkey -a '^[n' history-beginning-search-forward  # '^F'
bindkey '^R' history-incremental-search-backward
bindkey -a '^R' history-incremental-search-backward

# Bind up arrow and down arrow on the cmd line to scroll through history
autoload -U up-line-or-beginning-search
autoload -U down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
bindkey "^[[A" up-line-or-beginning-search
bindkey "^[[B" down-line-or-beginning-search

# Prompt editing
"\C-a": beginning-of-line
"\C-e": end-of-line

