# shellcheck shell=sh
#!/bin/bash
if [[ "" == "bash" ]]; then
  echo "ERROR: This script must be sourced, not executed."
  exit 1
fi
# =====================================================================
# Bash-It Initialization
# =====================================================================

# Load Bash-it if installed
if [ -d "$HOME/.bash_it" ]; then
  # shellcheck source=/dev/null
  source "$HOME/.bash_it/bash_it.sh"
fi

# =====================================================================
# End of Bash-It Initialization
# =====================================================================
