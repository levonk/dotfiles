#!/bin/sh
# Start a clipboard manager appropriate to the session. Home-only, guarded.
set -eu

start_wayland() {
  if command -v wl-clipboard-history >/dev/null 2>&1; then
    exec wl-clipboard-history -t >/dev/null 2>&1
  fi
}

start_x11() {
  if command -v parcellite >/dev/null 2>&1; then
    exec parcellite >/dev/null 2>&1
  fi
  if command -v clipmenud >/dev/null 2>&1; then
    exec clipmenud >/dev/null 2>&1
  fi
}

case "${XDG_SESSION_TYPE:-}" in
  wayland|Wayland)
    start_wayland || true ;;
  x11|X11)
    start_x11 || true ;;
  *)
    start_wayland || start_x11 || true ;;
 esac

exit 0
