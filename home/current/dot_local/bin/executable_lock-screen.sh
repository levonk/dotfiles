#!/usr/bin/env sh
# Lock screen dispatcher (home-only). Chooses a locker based on session/available tools.
set -eu

lock_wayland() {
  if command -v swaylock >/dev/null 2>&1; then
    exec swaylock -f
  fi
  # Add other Wayland lockers here if desired
}

lock_x11() {
  if command -v i3lock >/dev/null 2>&1; then
    exec i3lock -n
  fi
  if command -v betterlockscreen >/dev/null 2>&1; then
    exec betterlockscreen -l
  fi
  if command -v xscreensaver-command >/dev/null 2>&1; then
    exec xscreensaver-command -lock
  fi
}

case "${XDG_SESSION_TYPE:-}" in
  wayland|Wayland)
    lock_wayland || true ;;
  x11|X11)
    lock_x11 || true ;;
  *)
    # Try Wayland first, then X11
    lock_wayland || lock_x11 || true ;;
 esac

# Fallback: do nothing gracefully
exit 0
