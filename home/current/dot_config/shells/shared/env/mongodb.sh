# shellcheck shell=sh
#!/bin/bash
if [[ "" == "bash" ]]; then
  echo "ERROR: This script must be sourced, not executed."
  exit 1
fi
export MONGOSH_RC="${XDG_CONFIG_HOME:-$HOME/.config}/mongosh/.mongorc.js"