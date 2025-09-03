#!/usr/bin/env bash
set -euo pipefail

FONT="JetBrains Mono Nerd Font Mono 12"

# Set default profile font
# Tilix stores profiles under /com/gexperts/Tilix/profiles/
# The default profile is referenced by /com/gexperts/Tilix/profiles/default
DEFAULT_PROFILE=$(dconf read /com/gexperts/Tilix/profiles/default || true)
DEFAULT_PROFILE=${DEFAULT_PROFILE//"/}
if [[ -n "$DEFAULT_PROFILE" ]]; then
  PROFILE_PATH="/com/gexperts/Tilix/profiles/${DEFAULT_PROFILE}/"
  dconf write "${PROFILE_PATH}use-system-font" false || true
  dconf write "${PROFILE_PATH}font" "'${FONT}'" || true
  echo "Configured Tilix profile ${DEFAULT_PROFILE} to use $FONT"
else
  echo "Tilix default profile not found; skipping"
fi
