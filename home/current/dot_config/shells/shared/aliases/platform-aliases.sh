#!/usr/bin/env sh
# shellcheck shell=sh
#{{- includeTemplate "dot_config/ai/templates/shell/sourceable.sh.tmpl" (dict "path" .path "name" .name) -}}


# =====================================================================
# Platform/OS utility aliases (modularized from legacy sharedrc/aliases)
# Shell-neutral unless otherwise noted. See README for exceptions.

# List open network sockets (cross-platform)
if command -v lsof >/dev/null 2>&1; then
  alias ports='sudo lsof -i -P -n | grep LISTEN'
elif command -v netstat >/dev/null 2>&1; then
  alias ports='netstat -tulpn | grep LISTEN'
fi

# Show disk usage in human-readable form
alias duh='du -h --max-depth=1'

# Show free disk space
alias dfh='df -h'

# Show top processes by memory/cpu
alias psmem='ps aux --sort=-%mem | head -n 10'
alias pscpu='ps aux --sort=-%cpu | head -n 10'

# macOS-specific: show battery status
if [ "$(uname)" = "Darwin" ]; then
  alias battery='pmset -g batt'
fi

# Windows-specific: open explorer
if [[ "$OS" == "Windows_NT" ]] || grep -qiE 'mingw|cygwin|msys' <<< "$(uname)"; then
  alias explorer='explorer.exe .'
fi
