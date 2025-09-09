# shellcheck shell=sh
#!/bin/bash
if [[ "" == "bash" ]]; then
  echo "ERROR: This script must be sourced, not executed."
  exit 1
fi
#!/usr/bin/env bash
# smite-loader: registers a lazy trigger 'smite' that loads shell-specific implementation
# - Does not define smite itself here; relies on lazy-loader's trigger mechanism
# - Avoids editing dot_*rc by integrating with existing lazy loader registration

# Require lazy loader functions
if ! command -v register_lazy_module >/dev/null 2>&1; then
  # If lazy loader isn't loaded yet, just return quietly; entrypoint will source this later again
  return 0 2>/dev/null || true
fi

XDG_CONFIG_HOME=${XDG_CONFIG_HOME:-"$HOME/.config"}
SHELLS_BASE_DIR="$XDG_CONFIG_HOME/shells"

# Determine current shell and appropriate module path
module_name=""
smite_module_path=""
case "${ZSH_VERSION:+zsh}${BASH_VERSION:+bash}" in
  zsh)
    module_name="zsh_util_smite"
    smite_module_path="$SHELLS_BASE_DIR/zsh/util/smite.zsh"
    ;;
  bash)
    module_name="bash_util_smite"
    smite_module_path="$SHELLS_BASE_DIR/bash/util/smite.bash"
    ;;
  *)
    # Try to infer from $SHELL
    case "${SHELL##*/}" in
      zsh)
        module_name="zsh_util_smite"; smite_module_path="$SHELLS_BASE_DIR/zsh/util/smite.zsh" ;;
      bash)
        module_name="bash_util_smite"; smite_module_path="$SHELLS_BASE_DIR/bash/util/smite.bash" ;;
      *)
        # Unknown shell; do not register
        return 0 2>/dev/null || true
        ;;
    esac
    ;;
esac

# Only register if the module file exists and smite isn't already defined
if [ -r "$smite_module_path" ] && ! command -v smite >/dev/null 2>&1; then
  register_lazy_module "$module_name" "$smite_module_path" "smite"
fi
