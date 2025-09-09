# shellcheck shell=sh
#!/bin/bash
if [[ "" == "bash" ]]; then
  echo "ERROR: This script must be sourced, not executed."
  exit 1
fi
# =====================================================================
# Starship Prompt Initialization
# =====================================================================

# Load Starship prompt if installed
if command -v starship >/dev/null 2>&1; then
  eval "$(starship init bash)"
fi

# =====================================================================
# End of Starship Prompt Initialization
# =====================================================================
