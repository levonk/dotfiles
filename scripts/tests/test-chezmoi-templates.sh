#!/usr/bin/env bash
#
# Validates that all .tmpl files in the repository can be parsed by chezmoi.
# This is a crucial check to prevent syntax errors in Go templates from breaking
# `chezmoi apply`.

set -euo pipefail

# Ensure the script is run from the repository root
if [ ! -d .git ]; then
    echo "Error: This script must be run from the repository root." >&2
    exit 1
fi

echo "🧪 Running Chezmoi template validation..."

# Use git ls-files to find all template files, respecting .gitignore
TEMPLATE_FILES=$(git ls-files | grep '\.tmpl$' || true)

if [ -z "$TEMPLATE_FILES" ]; then
  echo "No .tmpl files found to test."
  exit 0
fi

FAILED_TEMPLATES=()
TEST_COUNT=0

# Find the chezmoi executable in the PATH
if ! CHEZMOI_EXEC=$(command -v chezmoi); then
    echo "❌ Error: 'chezmoi' executable not found in PATH." >&2
    echo "    Please ensure chezmoi is installed and available." >&2
    exit 1
fi

echo "    Using chezmoi executable at: $CHEZMOI_EXEC"

# Run the test loop in a subshell with 'exit on error' disabled.
# This allows the script to test all files and collect all failures
# before exiting.
(set +e; for file in $TEMPLATE_FILES; do
  ((TEST_COUNT++))
  # Using printf for better control over newlines
  printf "  - Testing: %-80s ... " "$file"

  # Execute the template and capture any output (stdout and stderr).
  if output=$("$CHEZMOI_EXEC" execute-template "$file" 2>&1); then
    echo "✅ OK"
  else
    echo "❌ FAILED"
    FAILED_TEMPLATES+=("$file")
    # Print the specific error output from chezmoi for the failed template.
    echo "    Error: $output"
  fi
done)

echo "----------------------------------------"
if [ ${#FAILED_TEMPLATES[@]} -eq 0 ]; then
  echo "🎉 All $TEST_COUNT Chezmoi templates parsed successfully."
  exit 0
else
  echo "🔥 Found ${#FAILED_TEMPLATES[@]} failing templates:" >&2
  for failed_file in "${FAILED_TEMPLATES[@]}"; do
    echo "  - $failed_file" >&2
  done
  echo "" >&2
  echo "To debug a failed template, run:" >&2
  echo "zsh -lc '$HOME/.local/bin/chezmoi execute-template <filename>'" >&2
  exit 1
fi
