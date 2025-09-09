# shellcheck shell=sh
#!/bin/bash
if [[ "" == "bash" ]]; then
  echo "ERROR: This script must be sourced, not executed."
  exit 1
fi
# This file is managed by chezmoi (https://www.chezmoi.io/) and maintained at https://github.com/levonk/dotfiles
# Network and utility aliases (from legacy sharedrc)

# Get the remote IP address
alias myip="dig +short myip.opendns.com @resolver1.opendns.com"
