#!/bin/bash
# =====================================================================
# PATH Ordering Utility
# Managed by chezmoi | https://github.com/levonk/dotfiles
#
# Purpose:
#   - In WSL, ensure Linux paths precede Windows-mapped paths in $PATH
#   - Keep original relative order within Linux and within Windows segments
#   - Deduplicate segments while preserving first occurrence
#
# Safety:
#   - No network access, no external commands required
#   - Pure string processing; does not add/remove entries, only reorders
#
# Dependencies:
#   - Relies on platform-detection.sh having set is_wsl()
# =====================================================================

# Return 0 (true) if the PATH segment looks like a Windows path in WSL
__is_windowsish_path_segment() {
  local seg="$1"
  # Empty or dot-like segments are not considered windows-ish
  [ -z "$seg" ] && return 1

  # Common indicators:
  # - /mnt/<drive>/...
  # - Drive letter paths: C:/..., c:/...
  # - Backslashes or Program Files/Windows keywords
  case "$seg" in
    /mnt/[a-z]/*) return 0 ;;
    [A-Za-z]:/*) return 0 ;;
    *\\*) return 0 ;;
    */Windows/*) return 0 ;;
    */Program\ Files*|*/Program%20Files*) return 0 ;;
  esac
  return 1
}

# Reorder PATH so that non-Windows-ish (Linux) segments come first, then Windows-ish
reorder_path_linux_first() {
  # Only act once per shell process
  if [ -n "${DOTFILES_PATH_REORDERED:-}" ]; then
    return 0
  fi

  # Shells or tooling might not have PATH set; guard
  if [ -z "${PATH:-}" ]; then
    return 0
  fi

  local IFS=':'
  # Read current PATH into an array
  # shellcheck disable=SC2206
  local parts=( $PATH )

  local -a linux_parts
  local -a win_parts
  linux_parts=()
  win_parts=()

  # Dedup set
  local seen="|"

  for seg in "${parts[@]}"; do
    # Normalize repeated separators resulting in empty entries
    [ -z "$seg" ] && continue

    # Deduplicate by exact segment
    case "$seen" in
      *"|$seg|"*) continue ;;
    esac

    if __is_windowsish_path_segment "$seg"; then
      win_parts+=("$seg")
    else
      linux_parts+=("$seg")
    fi

    seen="${seen}${seg}|"
  done

  # Reassemble PATH: linux-first, then windows-ish
  local new_path
  if [ ${#linux_parts[@]} -gt 0 ] && [ ${#win_parts[@]} -gt 0 ]; then
    new_path="$(IFS=':'; echo "${linux_parts[*]}:${win_parts[*]}")"
  elif [ ${#linux_parts[@]} -gt 0 ]; then
    new_path="$(IFS=':'; echo "${linux_parts[*]}")"
  else
    new_path="$(IFS=':'; echo "${win_parts[*]}")"
  fi

  # Only export if it actually changed
  if [ "$new_path" != "$PATH" ]; then
    PATH="$new_path"
    export PATH
  fi

  # Mark as done for this process
  DOTFILES_PATH_REORDERED=1
}

# Note: Do NOT auto-run. This utility is opt-in to avoid unintended changes.
# To enable on-demand in a session:
#   if command -v reorder_path_linux_first >/dev/null; then reorder_path_linux_first; fi
