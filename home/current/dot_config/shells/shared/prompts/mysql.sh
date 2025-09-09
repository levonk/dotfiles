# shellcheck shell=sh
#!/bin/bash
if [[ "" == "bash" ]]; then
  echo "ERROR: This script must be sourced, not executed."
  exit 1
fi
# This file is managed by chezmoi (https://www.chezmoi.io/) and maintained at https://github.com/levonk/dotfiles
export MYSQL_PROMPT="\\\\[\\\\033[32m\\\\]\\u@\\h:\\d> \\\\[\\\\033[0m\\\\]"