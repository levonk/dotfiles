#!/usr/bin/env bash
set -euo pipefail

# Set up a minimal environment similar to the test
export HOME="$(mktemp -d)"
export XDG_CONFIG_HOME="$HOME/.config"
mkdir -p "$XDG_CONFIG_HOME"

# Copy the shell configs into the temp home
cp -R "/home/micro/p/gh/levonk/dotfiles/home/current/dot_config/shells" "$XDG_CONFIG_HOME/"

# Source the entrypoint and check the variable
echo "--- Sourcing entrypoint --- "
# shellcheck source=/dev/null
. "$XDG_CONFIG_HOME/shells/shared/entrypointrc.sh"
echo "--- Source complete ---"

echo "STARTUP_TEST_ENV is: [${STARTUP_TEST_ENV:-EMPTY}]"

# Clean up
rm -rf "$HOME"
