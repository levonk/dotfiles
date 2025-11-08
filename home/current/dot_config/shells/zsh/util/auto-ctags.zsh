#!/usr/bin/env zsh
# shellcheck shell=zsh

# =====================================================================

# Zsh-specific ctags integration

# Description: This script automatically generates ctags for a project
#              when you change into its directory.

# This function is triggered by the chpwd hook (see below).
function auto_ctags() {
  # Skip running in the home directory to avoid indexing all of $HOME
  if [ "$PWD" = "$HOME" ] || [ "$PWD/" = "$HOME/" ]; then
    return 0
  fi

  # Check for a .ctags file or a src/ directory to identify a project root
  if [ -f ".ctags" ] || [ -d "src" ]; then
    echo "Indexing with ctags..."
    ctags -R .
  fi
}

# Load the add-zsh-hook utility if it's not already available
autoload -U add-zsh-hook

# Register the auto_ctags function to run every time the directory is changed
add-zsh-hook chpwd auto_ctags
