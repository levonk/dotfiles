#!/usr/bin/env bash
# shellcheck shell=bash
#{{ includeTemplate "home/current/dot_config/ai/templates/shell/executable_executable.bash.tmpl" (dict "style" "shell") }}

if ! command -v ssh-keygen >/dev/null 2>&1; then
  echo "Error: ssh-keygen not found in PATH" >&2
  exit 127
fi

ssh-keygen -p -f ~/.ssh/id_rsa
