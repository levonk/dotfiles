#!/usr/bin/env sh
# shellcheck shell=sh
#{{- includeTemplate "dot_config/ai/templates/shell/sourceable.sh.tmpl" (dict "path" .path "name" .name) -}}


# =====================================================================

#!/usr/bin/env sh
# Cross-shell mv wrapper (Bash/Zsh compatible)
# - Git-aware: uses 'git mv' when source file is tracked AND destination is within the same git repository
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

# Implementation: git-aware mv with prompt-supported rename
__mvw_prompt() {
  # SPECIAL CASE: Single file rename with interactive prompt
  # If exactly one argument and it's a regular file, prompt user for new filename
  # This enables: mv file.txt → [prompts] → mv file.txt newname.txt
  if [ "$#" -eq 1 ] && [ -f "$1" ]; then
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

    # Use git-aware mv for the rename operation
    __mvw_git_aware_mv "$src" "$newfilename"
    return $?
  fi

  # ALL OTHER CASES: Use git-aware mv logic
  # This includes:
  # - Multi-argument moves: mv file1 file2 dest/  → git-aware if applicable
  # - Directory moves: mv dir1 dir2  → git-aware if applicable  
  # - Non-regular files: mv symlink dest/  → git-aware if applicable
  # - Any other mv operation not caught by the single-file rename case
  __mvw_git_aware_mv "$@"
  return $?
}

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

  # Use git-aware mv for the rename operation
  __mvw_git_aware_mv "$src" "$newfilename"
}

# Git-aware mv: use git mv if file is tracked and destination is within git repo
__mvw_git_aware_mv() {
  # If not exactly 2 args (source and dest), or source doesn't exist, use regular mv
  if [ "$#" -ne 2 ] || [ ! -e "$1" ]; then
    __mvw_regular_mv "$@"
    return $?
  fi

  src="$1"
  dest="$2"

  # Check if we're in a git repository
  if ! git rev-parse --git-dir >/dev/null 2>&1; then
    __mvw_regular_mv "$@"
    return $?
  fi

  # Get the git repository root
  git_root="$(git rev-parse --show-toplevel 2>/dev/null)"
  if [ -z "$git_root" ]; then
    __mvw_regular_mv "$@"
    return $?
  fi

  # Check if source file is tracked by git
  if ! git ls-files --error-unmatch "$src" >/dev/null 2>&1; then
    __mvw_regular_mv "$@"
    return $?
  fi

  # Resolve destination to absolute path
  if [ -d "$dest" ]; then
    # If dest is a directory, construct the full path
    dest_file="$(basename "$src")"
    dest_path="$dest/$dest_file"
  else
    dest_path="$dest"
  fi

  # Get absolute path of destination
  if command -v realpath >/dev/null 2>&1; then
    dest_abs="$(realpath -m "$dest_path" 2>/dev/null)"
  elif command -v readlink >/dev/null 2>&1; then
    dest_abs="$(readlink -f "$dest_path" 2>/dev/null || readlink -m "$dest_path" 2>/dev/null)"
  else
    # Fallback: try to construct absolute path
    case "$dest_path" in
      /*) dest_abs="$dest_path" ;;
      *) dest_abs="$PWD/$dest_path" ;;
    esac
  fi

  # Check if destination is within the git repository
  case "$dest_abs" in
    "$git_root"/*)
      # Destination is within git repo, use git mv
      printf 'Using git mv: %s -> %s\n' "$src" "$dest"
      git mv "$src" "$dest"
      ;;
    *)
      # Destination is outside git repo, use regular mv
      __mvw_regular_mv "$@"
      ;;
  esac
}

# Regular mv with directory creation
__mvw_regular_mv() {
  # Ensure destination directory exists for single-file operations
  if [ "$#" -eq 2 ] && [ -f "$1" ] && [ ! -d "$2" ]; then
    # Use POSIX dirname fallback if coreutils dirname unavailable
    if command -v dirname >/dev/null 2>&1; then
      destdir="$(dirname -- "$2" 2>/dev/null || dirname "$2")"
    else
      destdir="${2%/*}"
      [ "$destdir" = "$2" ] && destdir=""
    fi

    if [ -n "$destdir" ] && [ ! -d "$destdir" ]; then
      mkdir -p -- "$destdir"
      printf 'Created destination directory: %s\n' "$destdir"
    fi
  fi

  command mv -v -- "$@"
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
