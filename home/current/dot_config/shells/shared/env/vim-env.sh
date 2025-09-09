# shellcheck shell=sh
#!/bin/bash
if [[ "" == "bash" ]]; then
  echo "ERROR: This script must be sourced, not executed."
  exit 1
fi
export VIMINIT="source ${XDG_CONFIG_HOME:-$HOME/.config}/nvim/vimrc"
