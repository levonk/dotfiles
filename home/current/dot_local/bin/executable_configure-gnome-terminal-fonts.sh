#!/usr/bin/env bash
set -euo pipefail

FONT="JetBrains Mono Nerd Font Mono 12"

# Get default profile UUID
PROFILE_ID=$(gsettings get org.gnome.Terminal.ProfilesList default | tr -d "'" )
PROFILE_PATH="/org/gnome/terminal/legacy/profiles:/:${PROFILE_ID}/"

if [[ -n "$PROFILE_ID" ]]; then
  gsettings set "org.gnome.Terminal.Legacy.Profile:${PROFILE_PATH}" use-system-font false || true
  gsettings set "org.gnome.Terminal.Legacy.Profile:${PROFILE_PATH}" font "$FONT" || true
fi

echo "Configured GNOME Terminal profile ${PROFILE_ID:-unknown} to use $FONT"
