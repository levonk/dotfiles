#!/usr/bin/env sh
# shellcheck shell=sh
#{{- includeTemplate "dot_config/ai/snippets/shell/sourceable.sh.tmpl" (dict "path" .path "name" .name) -}}


# =====================================================================

# ==============================================================================
# Modern Tool Notification & Spell Correction Plugin
# Managed by chezmoi | https://github.com/levonk/dotfiles
# Purpose:
#   - Notifies user in real time when using legacy tools, recommends modern alternatives.
#   - Provides spell correction for common CLI typos.
# Shell Support:
#   - Fully supported: Zsh, Bash (uses preexec/DEBUG hooks)
#   - No-op in unsupported shells (safe to source everywhere)
#   - Kept in shells/shared for unified maintenance and future extensibility.
#   - Extensible: Add more shells or features as needed.
# Security: No sensitive data, no external calls, safe for all environments.
# ==============================================================================

# --- Modern tool mapping (loaded from .ini) ---
MODERN_TOOL_MAP=""
MODERN_TOOL_MAP_FILE="${SHARED_DIR:-$HOME/.config/shells/shared/env}/modern-tool-map.ini"
if [ -f "$MODERN_TOOL_MAP_FILE" ]; then
  while IFS= read -r line; do
    case "$line" in
      ''|\#*) continue ;; # skip blank/comments
      *) MODERN_TOOL_MAP="$MODERN_TOOL_MAP${MODERN_TOOL_MAP:+\n}$line" ;;
    esac
  done < "$MODERN_TOOL_MAP_FILE"
fi

# --- Real-time notification function ---
modern_tool_notify() {
  cmd="$1"
  # Only notify for interactive shells
  [ -t 1 ] || return 0
  # Find modern equivalent
  modern=""
  while IFS=: read -r legacy modern_candidate; do
    modern_cmd="${modern_candidate%% *}" # only the first word
    if [ "$cmd" = "$legacy" ] && command -v "$modern_cmd" >/dev/null 2>&1; then
      modern="$modern_candidate"
      break
    fi
  done <<EOF
$MODERN_TOOL_MAP
EOF
  if [ -n "$modern" ]; then
    printf '\033[1;33m[dotfiles] Consider using modern tool: %s (Using %s instead)\033[0m\n' "$modern" "$modern"
  fi
}

# --- Spell correction and notification wrapper ---
# Only for supported shells (Zsh/Bash)
if [ -n "$ZSH_VERSION" ]; then
  # Zsh: Use preexec hook
  function preexec_modern_tool_notify() {
    local cmd=${1%% *}
    modern_tool_notify "$cmd"
  }
  autoload -Uz add-zsh-hook
  add-zsh-hook preexec preexec_modern_tool_notify
elif [ -n "$BASH_VERSION" ]; then
  # Bash: Use DEBUG trap
  trap 'modern_tool_notify "${BASH_COMMAND%% *}"' DEBUG
fi

# --- Optional: Spell correction (simple) ---
# Recommend correct spelling for common legacy tool typos
spell_corrections="grpe:grep\nmroe:more\nmoer:more\nsl:ls"
spell_correct_notify() {
  cmd="$1"
  [ -t 1 ] || return 0
  while IFS=: read -r typo correct; do
    if [ "$cmd" = "$typo" ]; then
      printf '\033[1;31m[dotfiles] Did you mean: %s?\033[0m\n' "$correct"
      break
    fi
  done <<EOF
$spell_corrections
EOF
}
if [ -n "$ZSH_VERSION" ]; then
  function preexec_spell_correct_notify() {
    local cmd=${1%% *}
    spell_correct_notify "$cmd"
  }
  add-zsh-hook preexec preexec_spell_correct_notify
elif [ -n "$BASH_VERSION" ]; then
  trap 'spell_correct_notify "${BASH_COMMAND%% *}"' DEBUG
fi
