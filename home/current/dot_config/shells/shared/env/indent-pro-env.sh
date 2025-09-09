# shellcheck shell=sh
#!/bin/bash
if [[ "" == "bash" ]]; then
  echo "ERROR: This script must be sourced, not executed."
  exit 1
fi
export INDENT_PROFILE=${XDG_CONFIG_HOME:-$HOME/.config}/indent-pro/indent-pro.conf
