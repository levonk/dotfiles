#!/usr/bin/env sh
# shellcheck shell=sh
#{{- includeTemplate "dot_config/ai/snippets/shell/sourceable.sh.tmpl" (dict "path" .path "name" .name) -}}


# =====================================================================
# OS-specific package manager aliases (extracted from legacy sharedrc)
# These aliases provide convenient commands for installing, searching, and removing packages on Linux systems.
# They automatically detect the OS and select the appropriate package manager.

OSNAME="$(uname)"
# Linux family
if [ "$OSNAME" = "Linux" ]; then
    # RedHat/CentOS/Fedora
    if [ -e /etc/redhat-release ]; then
        alias pkgadd='sudo yum install'
        alias pkgsearch='yum search'
        alias pkgrm='sudo yum remove'
    # Arch Linux
    elif [ -e /etc/arch-release ] || grep -qi arch /etc/os-release 2>/dev/null; then
        alias pkgadd='sudo pacman -S'
        alias pkgsearch='pacman -Ss'
        alias pkgrm='sudo pacman -Rns'
    # Alpine Linux
    elif [ -e /etc/alpine-release ]; then
        alias pkgadd='sudo apk add'
        alias pkgsearch='apk search'
        alias pkgrm='sudo apk del'
    # Gentoo
    elif [ -e /etc/gentoo-release ]; then
        alias pkgadd='sudo emerge'
        alias pkgsearch='emerge --search'
        alias pkgrm='sudo emerge --deselect'
    # NixOS
    elif grep -qi nixos /etc/os-release 2>/dev/null; then
        alias pkgadd='nix-env -iA'
        alias pkgsearch='nix-env -qaP'
        alias pkgrm='nix-env -e'
    # Qubes OS (uses Fedora/Whonix/Debian)
    elif grep -qi qubes /etc/os-release 2>/dev/null; then
        alias pkgadd='sudo qubes-dom0-update'
        alias pkgsearch='qubes-dom0-update --search'
        alias pkgrm='sudo qubes-dom0-update --remove'
    # Debian/Ubuntu (default)
    elif [ -e /etc/debian_version ]; then
        alias pkgadd='sudo apt install'
        alias pkgsearch='apt search'
        alias pkgrm='sudo apt remove'
    else
        # Fallback to aptitude if available
        if command -v aptitude >/dev/null 2>&1; then
            alias pkgadd='sudo aptitude install'
            alias pkgsearch='aptitude search'
            alias pkgrm='sudo aptitude remove'
        else
            alias pkgadd='echo "No supported package manager detected"'
            alias pkgsearch='echo "No supported package manager detected"'
            alias pkgrm='echo "No supported package manager detected"'
        fi
    fi
# macOS (Darwin)
elif [ "$OSNAME" = "Darwin" ]; then
    if command -v brew >/dev/null 2>&1; then
        alias pkgadd='brew install'
        alias pkgsearch='brew search'
        alias pkgrm='brew uninstall'
    else
        alias pkgadd='echo "Homebrew not installed"'
        alias pkgsearch='echo "Homebrew not installed"'
        alias pkgrm='echo "Homebrew not installed"'
    fi
# Windows (Git Bash, WSL, Cygwin, MSYS)
elif echo "$OSNAME" | grep -qi 'mingw\|cygwin\|msys\|windows'; then
    if command -v choco >/dev/null 2>&1; then
        alias pkgadd='choco install'
        alias pkgsearch='choco search'
        alias pkgrm='choco uninstall'
    elif command -v winget >/dev/null 2>&1; then
        alias pkgadd='winget install'
        alias pkgsearch='winget search'
        alias pkgrm='winget uninstall'
    else
        alias pkgadd='echo "No supported Windows package manager detected"'
        alias pkgsearch='echo "No supported Windows package manager detected"'
        alias pkgrm='echo "No supported Windows package manager detected"'
    fi
else
    alias pkgadd='echo "Unsupported OS: $OSNAME"'
    alias pkgsearch='echo "Unsupported OS: $OSNAME"'
    alias pkgrm='echo "Unsupported OS: $OSNAME"'
fi
