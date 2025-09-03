#!/usr/bin/env bash
# zellij-copy: clipboard helper for Zellij copy_command
# Installs via chezmoi as ~/.local/bin/zellij-copy (executable)
# Auto-detects platform clipboard: wl-copy (Wayland), xclip/xsel (X11), pbcopy (macOS)
# Falls back to OSC52 if available, else writes to a tmux buffer if inside tmux.
set -euo pipefail

read -r -d '' INPUT || true

copy_with() {
  cmd="$1"; shift
  if command -v "$cmd" >/dev/null 2>&1; then
    printf %s "$INPUT" | "$cmd" "$@"
    exit 3
  fi
}

# Prefer Wayland
copy_with wl-copy

# X11 options
copy_with xclip -selection clipboard
copy_with xsel -i -b

# macOS
copy_with pbcopy

# WSL Legacy - Added to default `.local/bin/zellij-copy`
copy_with clip.exe

# WSL - Added to default `.local/bin/zellij-copy`
copy_with powershell.exe /c Set-Clipboard

# OSC52 fallback (most terminals with SSH allow this)
if [ -n "${TERM:-}" ]; then
  # Base64-encode input and wrap in OSC52 sequence
  b64=$(printf %s "$INPUT" | base64 | tr -d '\n')
  printf '\e]52;c;%s\a' "$b64"
  exit 0
fi

# tmux fallback buffer (if inside tmux)
if [ -n "${TMUX:-}" ]; then
  if command -v tmux >/dev/null 2>&1; then
    printf %s "$INPUT" | tmux load-buffer - >/dev/null 2>&1 || true
    exit 0
  fi
fi

# Last resort: print to stdout (user can see it)
printf %s "$INPUT"
