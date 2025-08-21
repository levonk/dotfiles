# This file is managed by chezmoi (https://www.chezmoi.io/) and maintained at https://github.com/levonk/dotfiles
# =====================================================================
# Zsh Keybinds Management
# =====================================================================

# History Search Keybindings
bindkey "$terminfo[kcuu1]" up-line-or-beginning-search # Up Arrow
bindkey "$terminfo[kcud1]" down-line-or-beginning-search # Down Arrow
bindkey '^R' history-incremental-search-backward

# Alt+p for history substring search backward
bindkey "\e[p" history-beginning-search-backward
# Alt+n for history substring search forward
bindkey "\e[n" history-beginning-search-forward

# Prompt editing
bindkey '^a' beginning-of-line
bindkey '^e' end-of-line

# Source completion (autocomplete)
zstyle ':completion:*' menu select

# =====================================================================
# End of Powerlevel10k Configuration
# =====================================================================
