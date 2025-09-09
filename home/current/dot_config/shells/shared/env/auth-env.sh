# shellcheck shell=sh
#!/bin/bash
if [[ "" == "bash" ]]; then
  echo "ERROR: This script must be sourced, not executed."
  exit 1
fi
## Anthropic Claude Code CLI tool
export ANTHROPIC_BASE_URL=
export ANTHROPIC_AUTH_TOKEN=