# ==============================================================================
# Legacy-to-Modern Tool Aliases
#
# Managed by chezmoi | https://github.com/levonk/dotfiles
#
# Purpose:
#   - Aliases legacy CLI tools to their modern replacements (if installed).
#   - Provides a seamless migration path for legacy habits to modern tools.
#
# Shell Support:
#   - Shell-neutral (POSIX): Only aliases if modern tool is present.
#   - Safe to source in any shell; no-op if tools not present.
#   - Kept in shells/shared for unified maintenance and future extensibility.
#
# Security: No sensitive data, no external calls, safe for all environments.
# ==============================================================================

# Only alias if modern tools are available

# grep -> ripgrep (rg)
if command -v rg >/dev/null 2>&1; then
  alias grep='rg'
  alias egrep='rg -e'
  alias fgrep='rg -F'
fi

# more -> less
if command -v less >/dev/null 2>&1; then
  alias more='less'
fi

# cat -> bat (syntax highlighting)
if command -v bat >/dev/null 2>&1; then
  alias cat='bat --paging=never'
fi

# find -> fd (simpler UX)
if command -v fd >/dev/null 2>&1; then
  alias find='fd'
fi

# cd -> zoxide (smarter cd)
if command -v zoxide >/dev/null 2>&1; then
  alias cd='z'
fi
