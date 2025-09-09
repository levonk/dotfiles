# shellcheck shell=sh
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
# shellcheck shell=sh

# Debug helper: show grep/egrep/fgrep status when DOTFILES_DEBUG_GREP=1
_dotfiles_debug_grep_status() {
  [ -n "${DOTFILES_DEBUG_GREP:-}" ] || return 0
  echo "[dotfiles][debug] grep status:"
  echo -n "  grep:  "; type -a grep 2>/dev/null || true
  echo -n "  egrep: "; type -a egrep 2>/dev/null || true
  echo -n "  fgrep: "; type -a fgrep 2>/dev/null || true
  if alias grep >/dev/null 2>&1; then echo "  alias grep=$(alias grep)"; fi
  if alias egrep >/dev/null 2>&1; then echo "  alias egrep=$(alias egrep)"; fi
  if alias fgrep >/dev/null 2>&1; then echo "  alias fgrep=$(alias fgrep)"; fi
}

_dotfiles_debug_grep_status

# Only alias if modern tools are available, using a shared mapping file
# Apply training aliases only in interactive shells to avoid breaking scripts
case $- in
  *i*)
    MODERN_TOOL_MAP_FILE="${SHARED_DIR:-$HOME/.config/shells/shared/env}/modern-tool-map.ini"
    if [ -f "$MODERN_TOOL_MAP_FILE" ]; then
      while IFS='=' read -r legacy modern; do
        case "$legacy" in
          ''|\#*) continue ;; # skip blank/comments
        esac
        # Avoid aliasing grep->rg during startup; can cause bare rg invocations
        if [ "$legacy" = "grep" ]; then
          [ -n "${DOTFILES_DEBUG_GREP:-}" ] && echo "[dotfiles][debug] skipping mapping: grep=$modern"
          continue
        fi
        [ -n "${DOTFILES_DEBUG_GREP:-}" ] && echo "[dotfiles][debug] applying mapping: $legacy=$modern"
        modern_cmd="${modern%% *}" # only the first word
        if command -v "$modern_cmd" >/dev/null 2>&1; then
          alias "$legacy"="$modern"
        fi
      done < "$MODERN_TOOL_MAP_FILE"
    fi
    ;;
  *) ;;
esac

_dotfiles_debug_grep_status

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

# Route grep/egrep/fgrep to wrapper scripts that emit hints and delegate to system grep
case $- in
  *i*)
    # Prefer user-local wrappers if present
    if [ -f "$HOME/.local/bin/grep" ]; then
      alias grep="bash $HOME/.local/bin/grep"
    else
      alias grep >/dev/null 2>&1 && unalias grep
    fi
    if [ -f "$HOME/.local/bin/egrep" ]; then
      alias egrep="bash $HOME/.local/bin/egrep"
    else
      alias egrep >/dev/null 2>&1 && unalias egrep
    fi
    if [ -f "$HOME/.local/bin/fgrep" ]; then
      alias fgrep="bash $HOME/.local/bin/fgrep"
    else
      alias fgrep >/dev/null 2>&1 && unalias fgrep
    fi
    ;;
  *) ;;
esac
