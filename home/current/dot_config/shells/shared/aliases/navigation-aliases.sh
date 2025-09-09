# shellcheck shell=sh
# ==============================================================================
# Navigation Aliases
#
# Managed by chezmoi | https://github.com/levonk/dotfiles
#
# Purpose:
#   - Provides quick directory navigation and bookmarking aliases.
#   - Integrates with modern tools (zoxide) if available.
#
# Shell Support:
#   - Shell-neutral (POSIX): Aliases and logic are safe for all shells.
#   - Kept in shells/shared for unified maintenance and future extensibility.
#
# Security: No sensitive data, no external calls, safe for all environments.
# ==============================================================================

# Go to frequently used directories (customize as needed)
alias cdd='cd ~/Downloads'
alias cddoc='cd ~/Documents'
alias cdp='cd ~/p'
alias cdpgh='cd ~/p/gh'
alias cdpbb='cd ~/p/bb'
alias cdpgl='cd ~/p/gl'
alias cdpghl='cd ~/p/gh/levonk'
alias cdpbbl='cd ~/p/bb/levonk'
alias cdpgll='cd ~/p/gl/levonk'

# Bookmarking system (see alias-helpers.sh for implementation)
# m1-m9, g1-g9, msave, mprint are defined in alias-helpers.sh

# Zoxide (if installed) for smart directory jumping
if command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init $(basename $SHELL))"
fi
