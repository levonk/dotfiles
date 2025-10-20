#!/usr/bin/env bash
# shellcheck shell=bash
#{{- includeTemplate "dot_config/ai/templates/shell/sourceable.bash.tmpl" (dict "path" .path "name" .name) -}}


# =====================================================================

#!/usr/bin/env bash
# smite (bash): interactively remove history entries by exact command match
# Requirements: fzf
# Caveats:
# - Must run in current interactive shell to mutate history
# - Bash lacks zsh's HISTORY_IGNORE prune; we delete by index scanning newest->oldest

smite() {
  # Ensure interactive shell and fzf availability
  case $- in
    *i*) : ;;
    *) echo 'smite: interactive shell required' >&2; return 1 ;;
  esac
  command -v fzf >/dev/null 2>&1 || { echo 'smite: fzf not found in PATH' >&2; return 127; }

  # Usage: smite (no flags supported in bash variant for simplicity)
  if [[ -n "${1:-}" ]]; then
    echo 'usage: smite' >&2
    return 1
  fi

  # Preserve current HISTTIMEFORMAT so we can strip timestamps
  local old_fmt=${HISTTIMEFORMAT-}
  # Temporarily clear to get plain list (index + command)
  HISTTIMEFORMAT=

  # Gather history lines: format "INDEX  COMMAND"; feed to fzf
  local selection
  selection=$(history | sed 's/^ *//' | fzf --no-sort --tac --multi) || { HISTTIMEFORMAT=$old_fmt; return $?; }
  [[ -z "$selection" ]] && { HISTTIMEFORMAT=$old_fmt; return 0; }

  # Extract selected commands (strip the leading index number and spaces)
  # Then for each unique command, delete all matching entries scanning from newest to oldest
  local cmd
  # Use awk to robustly split first field (index) from the rest
  while IFS='' read -r cmd; do
    cmd=${cmd#*[0-9] }   # naive strip; safer with awk below if available
  done < <(printf '%s\n' "$selection")

  # Recompute selection cleanly using awk to be safe across whitespace
  local commands
  commands=$(printf '%s\n' "$selection" | awk '{ $1=""; sub(/^ +/, ""); print }' | awk 'NF' | sort -u)

  local hist_line line_cmd
  local IFS_backup=$IFS
  IFS=$'\n'
  for cmd in $commands; do
    printf 'Removing history entries matching: "%s"\n' "$cmd"
    # Iterate history from newest to oldest to keep indices stable as we delete
    # We will repeatedly scan until no more matches are found (guard against duplicates)
    local changed=1
    while [[ $changed -eq 1 ]]; do
      changed=0
      # Refresh history snapshot each pass
      while read -r hist_line; do
        # hist_line like: " 1234  actual command..."
        local idx
        idx=$(sed -E 's/^ *([0-9]+)\s+.*/\1/' <<<"$hist_line")
        line_cmd=$(sed -E 's/^ *[0-9]+\s+(.*)$/\1/' <<<"$hist_line")
        if [[ "$line_cmd" == "$cmd" ]]; then
          # Delete this index; bash history -d expects a relative index; use builtin `history -d` with absolute index
          builtin history -d "$idx" >/dev/null 2>&1 || true
          changed=1
          break  # restart scan with fresh indices
        fi
      done < <(history | sed 's/^ *//')
    done
  done
  IFS=$IFS_backup

  # Restore HISTTIMEFORMAT
  HISTTIMEFORMAT=$old_fmt
}
