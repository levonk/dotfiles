#!/usr/bin/env zsh
# shellcheck shell=zsh
#{{- includeTemplate "dot_config/ai/templates/shell/sourceable.zsh.tmpl" (dict "path" .path "name" .name) -}}

# =====================================================================
# Zsh Keybinds Management
# =====================================================================

## Vi Mode, start in insert mode
bindkey -v

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
bindkey -M viins '^R' history-incremental-search-backward
bindkey -M viins '^S' history-incremental-search-forward
bindkey -M viins '^K' kill-line

# Alt+p for history substring search backward
bindkey "\e[p" history-beginning-search-backward
bindkey -a "\e[p" history-beginning-search-backward
# Alt+n for history substring search forward
bindkey "\e[n" history-beginning-search-forward
bindkey -a "\e[n" history-beginning-search-forward

# Prompt editing
bindkey '^a' beginning-of-line
bindkey '^e' end-of-line
# Delete from current cursor to start of line (apply in both vi maps)
bindkey -M viins '^u' backward-kill-line
bindkey -a '^u' backward-kill-line

# Source completion (autocomplete)
zstyle ':completion:*' menu select
