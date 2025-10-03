#!/usr/bin/env bash
#
# Test script to debug file discovery in entrypointrc.sh
#
set -euo pipefail

# Enable command tracing for debugging
set -x

# Get the absolute path to the project root
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
PROJECT_ROOT=$(cd -- "$SCRIPT_DIR/../.." &>/dev/null && pwd)

# Path to the script we are testing
ENTRYPOINT_SCRIPT="$PROJECT_ROOT/home/current/dot_config/shells/shared/entrypointrc.sh"

# We need to source the entrypoint to get the for_each_shell_file function.
# Set required variables to avoid errors during sourcing.
export XDG_CONFIG_HOME="$PROJECT_ROOT/home/current/dot_config"
export DOTFILES_CACHE_ENABLED=0 # Disable caching for the test
export DEBUG_MODULE_LOADING=1 # Enable debug output from the script

echo "--- Sourcing Entrypoint Script ---"
# Source the script and show any output
source "$ENTRYPOINT_SCRIPT" || {
    echo "ERROR: Sourcing entrypoint script failed." >&2
    exit 1
}
echo "--- Sourcing Complete ---"


# Check if the function is available
if ! command -v for_each_shell_file >/dev/null; then
    echo "ERROR: 'for_each_shell_file' function not found after sourcing." >&2
    exit 1
fi

# Set up a temporary test directory structure
TEST_DIR=$(mktemp -d)
# Ensure cleanup on exit
trap 'rm -rf -- "$TEST_DIR"' EXIT

# Mimic the real structure
TEST_ENV_DIR="$TEST_DIR/shared/env"
mkdir -p "$TEST_ENV_DIR"

# Create dummy files to be discovered
touch "$TEST_ENV_DIR/a-test-file.sh"
touch "$TEST_ENV_DIR/b-test-file.env"
touch "$TEST_ENV_DIR/c-test-file.bash"
touch "$TEST_ENV_DIR/d-test-file.txt" # This one should be ignored

echo "--- Test Setup ---"
echo "Test Directory: $TEST_ENV_DIR"
echo "Files created:"
ls -1 "$TEST_ENV_DIR"
echo "--------------------"
echo

# Run the function and capture its output
echo "--- Running Test ---"
echo "Calling: for_each_shell_file \"$TEST_ENV_DIR\" \"sh bash env\""
echo

# Execute the function and store the output
found_files=$(for_each_shell_file "$TEST_ENV_DIR" "sh bash env")

echo "--- Test Results ---"
if [ -n "$found_files" ]; then
    echo "✅ SUCCESS: The following files were found:"
    echo "$found_files"
else
    echo "❌ FAILURE: No files were found."
fi
echo "--------------------"
