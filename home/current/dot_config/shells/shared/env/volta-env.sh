# shellcheck shell=sh
#!/bin/bash
if [[ "" == "bash" ]]; then
  echo "ERROR: This script must be sourced, not executed."
  exit 1
fi
VOLTA_HOME="${XDG_CONFIG_HOME:-$HOME/.config}/volta"

# Only add to PATH if volta binary exists
if [ -x "$VOLTA_HOME/pnpm" ]; then
  case ":$PATH:" in
    *":$VOLTA_HOME:"*) ;;
    *) export PATH="$VOLTA_HOME:$PATH" ;;
  esac
fi
# volta end