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

# Only alias if modern tools are available, using a shared mapping file
MODERN_TOOL_MAP_FILE="${SHARED_DIR:-$HOME/.config/shells/shared}/modern-tool-map.ini"
if [ -f "$MODERN_TOOL_MAP_FILE" ]; then
  while IFS='=' read -r legacy modern; do
    case "$legacy" in
      ''|\#*) continue ;; # skip blank/comments
    esac
    modern_cmd="${modern%% *}" # only the first word
    if command -v "$modern_cmd" >/dev/null 2>&1; then
      # Special cases for options (bat/batcat, rg/egrep/fgrep, etc.) can be handled below or in a supplemental script
      alias "$legacy"="$modern"
    fi
  done < "$MODERN_TOOL_MAP_FILE"
fi

# vi/vim -> nvim (multi-alias logic)
if command -v nvim >/dev/null 2>&1; then
  alias vi='nvim'
  alias vim='nvim'
elif command -v vim >/dev/null 2>&1; then
  alias vi='vim'
fi

# Special-case: batcat
if command -v batcat >/dev/null 2>&1; then
  alias cat='batcat --paging=never'
fi
# Special-case: egrep/fgrep for rg
if command -v rg >/dev/null 2>&1; then
  alias egrep='rg -e'
  alias fgrep='rg -F'
fi
