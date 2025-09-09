#!/usr/bin/env sh
# shellcheck shell=sh
#{{- includeTemplate "dot_config/ai/snippets/shell/sourceable.sh.tmpl" (dict "path" .path "name" .name) -}}


# =====================================================================
# Typo-Fix Aliases
# Purpose:
#   - Corrects common CLI typos by aliasing to correct commands.
#   - Improves user experience and reduces friction for all users.
# Shell Support:
#   - Shell-neutral (POSIX): Aliases are safe for all shells.
#   - Kept in shells/shared for unified maintenance and future extensibility.
# Security: No sensitive data, no external calls, safe for all environments.
# ==============================================================================

# Common typo corrections
alias sl='ls'
alias l='ls -CF'
alias la='ls -A'
alias ll='ls -alF'
alias lla='ls -alF'
alias lsa='ls -a'
alias lsd='ls -d */'
alias cls='clear'
alias mroe='less'
alias moer='less'
alias grpe='rg'
alias grepq='rg -q'
alias egrepq='rg -q'
alias fgrepq='rg -q'
alias cd..='cd ..'
