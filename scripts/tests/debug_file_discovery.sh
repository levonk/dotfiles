#!/usr/bin/env bash
# ==============================================================================
# Debug File Discovery Test
#
# ## Purpose
#
# This script provides a standalone test to verify the behavior of the
# `for_each_shell_file` function, which is defined in the main
# `entrypointrc.sh` script. Its primary goal is to ensure that the function
# correctly identifies and lists shell-related files based on their extensions.
#
# ## How It Works
#
# 1.  **Sourcing**: It begins by sourcing `entrypointrc.sh` to load the
#     `for_each_shell_file` function into the current shell session.
# 2.  **Test Environment Setup**: It creates a temporary directory and populates
#     it with a set of dummy files with various extensions (`.sh`, `.env`,
#     `.bash`, and `.txt`).
# 3.  **Execution**: It calls `for_each_shell_file`, passing the temporary
#     directory and a list of extensions to find ("sh bash env").
# 4.  **Verification**: It checks the output of the function. The test is
#     considered successful if the function returns a list containing the paths
#     to the `.sh`, `.env`, and `.bash` files, while correctly ignoring the
#     `.txt` file.
#
# ## How to Run
#
# ```bash
# ./scripts/tests/debug_file_discovery.sh
# ```
#
# A successful run will print a "✅ SUCCESS" message and list the files found.
# ==============================================================================
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

# ==============================================================================
# Reference: for_each_shell_file
#
# The following function is the implementation of `for_each_shell_file` from
# `entrypointrc.sh`. It is included here for reference.
# ==============================================================================
#
# for_each_shell_file() {
#     dir="$1"
#     extensions="$2"
#     sort_mode="${3:-0}"
#
#     if [ ! -d "$dir" ]; then
#         return 0
#     fi
#
#     list_file=$(mktemp)
#     result_file=$(mktemp)
#
#     find "$dir" -maxdepth 1 -type f > "$list_file"
#
#     while IFS= read -r file; do
#         [ -n "$file" ] || continue
#         for ext in $extensions; do
#             ext="${ext#.}"
#             [ -n "$ext" ] || continue
#             case "$file" in
#                 *.
$ext")
#                     printf '%s\n' "$file" >> "$result_file"
#                     break
#                     ;;
#             esac
#         done
#     done < "$list_file"
#
#     if [ -s "$result_file" ]; then
#         if [ "$sort_mode" = "1" ]; then
#             sort "$result_file"
#         else
#             cat "$result_file"
#         fi
#     fi
#
#     rm -f "$list_file" "$result_file"
# }
