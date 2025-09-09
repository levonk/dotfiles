# shellcheck shell=sh
#!/bin/bash
if [[ "" == "bash" ]]; then
  echo "ERROR: This script must be sourced, not executed."
  exit 1
fi
#!/usr/bin/env zsh
# shellcheck disable=SC1071
# smite (zsh): interactively remove history entries by exact command match
# Requirements: fzf
# Notes:
# - Runs in the current shell to mutate history reliably
# - Uses zsh-specific options and fc semantics

function smite() {
  setopt LOCAL_OPTIONS ERR_RETURN PIPE_FAIL

  # interactive shell + fzf check
  if [[ ! -o interactive ]]; then
    print -u2 'smite: interactive shell required'
    return 1
  fi
  if ! command -v fzf >/dev/null 2>&1; then
    print -u2 'smite: fzf not found in PATH'
    return 127
  fi

  # usage: smite [-a]
  local opts=(-I)  # include duplicates collapsed; -a shows as-is
  if [[ "$1" == '-a' ]]; then
    opts=()
  elif [[ -n "$1" ]]; then
    print -u2 'usage: smite [-a]'
    return 1
  fi

  # Present history lines (without numbers) newest-last to fzf
  local selection
  selection=$(fc -l -n ${opts[@]} 1 | fzf --no-sort --tac --multi) || return $?

  # Nothing picked
  [[ -z "$selection" ]] && return 0

  # Iterate over each selected command line; delete all exact matches from history
  local command_to_delete
  # Use newline splitting but preserve spaces
  while IFS='' read -r command_to_delete; do
    [[ -z "$command_to_delete" ]] && continue
    printf 'Removing history entry "%s"\n' "$command_to_delete"

    # In zsh, setting HISTORY_IGNORE to the command bytes then writing & reloading prunes matches
    local HISTORY_IGNORE
    HISTORY_IGNORE="${(b)command_to_delete}"
    # Write current session to HISTFILE, then re-read with pruning based on HISTORY_IGNORE
    fc -W
    fc -p "$HISTFILE" "$HISTSIZE" "$SAVEHIST"
  done <<< "$selection"
}
