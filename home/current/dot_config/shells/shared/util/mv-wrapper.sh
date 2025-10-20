#!/usr/bin/env sh
# shellcheck shell=sh
#{{- includeTemplate "dot_config/ai/templates/shell/sourceable.sh.tmpl" (dict "path" .path "name" .name) -}}


# =====================================================================

#!/usr/bin/env sh
# Cross-shell mv wrapper (Bash/Zsh compatible)
# - If called with a single existing regular file, prompt to edit the target name inline.
# - Creates destination directory if it doesn't exist and notifies.
# - Delegates to real mv in all other cases.
# - Only enabled in interactive shells via alias to avoid breaking scripts.
# Bypass at any time with: command mv ...

# Shell detection (cheap)
__mvw_shell="unknown"
if [ -n "${ZSH_VERSION:-}" ]; then __mvw_shell="zsh";
elif [ -n "${BASH_VERSION:-}" ]; then __mvw_shell="bash";
else case "${0##*/}" in *zsh*) __mvw_shell="zsh";; *bash*) __mvw_shell="bash";; esac; fi

# Implementation: prompt-supported rename with mkdir -p for destination
__mvw_prompt() {
  # If not exactly one arg, or arg isn't a regular file, defer to system mv
  if [ "$#" -ne 1 ] || [ ! -f "$1" ]; then
    command mv "$@"
    return $?
  fi

  src="$1"
  newfilename="$src"

  # Prompt editing depending on shell
  if [ "$__mvw_shell" = "zsh" ] && command -v vared >/dev/null 2>&1; then
    vared -p "Rename to: " newfilename || return 1
  elif [ "$__mvw_shell" = "bash" ]; then
    # bash: -e enables readline, -i sets initial text
    # shellcheck disable=SC2162
    read -e -p "Rename to: " -i "$newfilename" newfilename || return 1
  else
    # Fallback POSIX prompt (no inline editing)
    printf 'Rename to [%s]: ' "$newfilename" >&2
    IFS= read newfilename || return 1
    [ -z "$newfilename" ] && newfilename="$src"
  fi

  # No change
  if [ "$newfilename" = "$src" ]; then
    printf 'No change: %s\n' "$src"
    return 0
  fi

  # Ensure destination directory exists
  # Use POSIX dirname fallback if coreutils dirname unavailable
  if command -v dirname >/dev/null 2>&1; then
    destdir="$(dirname -- "$newfilename" 2>/dev/null || dirname "$newfilename")"
  else
    destdir="${newfilename%/*}"
    [ "$destdir" = "$newfilename" ] && destdir=""
  fi

  if [ -n "$destdir" ] && [ ! -d "$destdir" ]; then
    mkdir -p -- "$destdir"
    printf 'Created destination directory: %s\n' "$destdir"
  fi

  command mv -v -- "$src" "$newfilename"
}

# Activate only in interactive shells
case $- in
  *i*) : ;; # interactive
  *) return 0 2>/dev/null || exit 0 ;; # non-interactive: do not alias
esac

# Avoid double aliasing if already set by user
if ! alias mv >/dev/null 2>&1; then
  alias mv='__mvw_prompt'
else
  # If user has an alias already, do not override silently; provide opt-in alias
  alias mvr='__mvw_prompt'
fi
