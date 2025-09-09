# shellcheck shell=sh
#!/bin/bash
if [[ "" == "bash" ]]; then
  echo "ERROR: This script must be sourced, not executed."
  exit 1
fi
export PSQLRC="${XDG_CONFIG_HOME:-$HOME/.config}"/psql/psqlrc.conf
