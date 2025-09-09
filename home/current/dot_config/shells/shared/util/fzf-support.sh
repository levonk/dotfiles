#!/usr/bin/env bash
# fzf-support: shared utility to detect fzf, expose installer hints, and enable key-bindings
# Safe for zsh/bash; sourced by sharedrc via util/* loader. No rc edits.

# Cache for detection
__DOTF_HAVE_FZF=""

have_fzf() {
  if [ -z "$__DOTF_HAVE_FZF" ]; then
    if command -v fzf >/dev/null 2>&1; then __DOTF_HAVE_FZF=1; else __DOTF_HAVE_FZF=0; fi
  fi
  [ "$__DOTF_HAVE_FZF" = 1 ]
}

# OS/distro detection (best-effort)
__fzf_detect_pkgmgr() {
  if command -v brew >/dev/null 2>&1; then echo "brew install fzf"; return; fi
  if [ -r /etc/os-release ]; then
    # shellcheck disable=SC1091
    . /etc/os-release
    case "$ID" in
      ubuntu|debian) echo "sudo apt update && sudo apt install -y fzf"; return ;;
      fedora) echo "sudo dnf install -y fzf"; return ;;
      rhel|centos|rocky|almalinux) echo "sudo yum install -y fzf || sudo dnf install -y fzf"; return ;;
      arch|manjaro) echo "sudo pacman -Syu fzf"; return ;;
      opensuse*|sles) echo "sudo zypper install -y fzf"; return ;;
      nixos) echo "nix-env -iA nixpkgs.fzf"; return ;;
    esac
  fi
  if command -v pacman >/dev/null 2>&1; then echo "sudo pacman -Syu fzf"; return; fi
  if command -v apt >/dev/null 2>&1; then echo "sudo apt install -y fzf"; return; fi
  if command -v dnf >/dev/null 2>&1; then echo "sudo dnf install -y fzf"; return; fi
  if command -v yum >/dev/null 2>&1; then echo "sudo yum install -y fzf"; return; fi
  if command -v zypper >/dev/null 2>&1; then echo "sudo zypper install -y fzf"; return; fi
  if command -v nix-env >/dev/null 2>&1; then echo "nix-env -iA nixpkgs.fzf"; return; fi
  echo "See https://github.com/junegunn/fzf#installation"
}

# Print installation guidance; do not run anything automatically
fzf:install() {
  local hint
  hint="$(__fzf_detect_pkgmgr)"
  printf '\n[dotfiles] fzf is required by certain utilities (e.g., smite).\n' >&2
  printf '[dotfiles] Install with:\n  %s\n\n' "$hint" >&2
  printf '[dotfiles] Optional: install shell key-bindings and completions after package install.\n' >&2
  printf '          Refer to: https://github.com/junegunn/fzf#key-bindings-for-command-line\n' >&2
}

# Attempt to source fzf key-bindings/completions when available
__fzf_source_if_exists() {
  # shellcheck disable=SC1090
  [ -r "$1" ] && . "$1"
}

__fzf_enable_shell_integration() {
  have_fzf || return 0
  # Common prefixes
  local BREW_PREFIX=""; BREW_PREFIX=$(brew --prefix 2>/dev/null || true)
  local CANDIDATES=()
  if [ -n "$BREW_PREFIX" ]; then
    CANDIDATES+=("$BREW_PREFIX/opt/fzf/shell")
  fi
  CANDIDATES+=(
    "/usr/share/fzf"
    "/usr/local/share/fzf"
    "$HOME/.fzf/shell"
  )
  # zsh
  if [ -n "${ZSH_VERSION:-}" ]; then
    for dir in "${CANDIDATES[@]}"; do
      __fzf_source_if_exists "$dir/key-bindings.zsh"
      __fzf_source_if_exists "$dir/completion.zsh"
    done
  fi
  # bash
  if [ -n "${BASH_VERSION:-}" ]; then
    for dir in "${CANDIDATES[@]}"; do
      __fzf_source_if_exists "$dir/key-bindings.bash"
      __fzf_source_if_exists "$dir/completion.bash"
    done
  fi
}

# Run once at shell init (safe no-op if not installed)
__fzf_enable_shell_integration
