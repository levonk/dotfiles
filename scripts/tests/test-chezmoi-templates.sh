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
CHEZMOI_EXEC="$HOME/.local/bin/chezmoi"

# Check if chezmoi executable exists
if [ ! -x "$CHEZMOI_EXEC" ]; then
    echo "❌ Error: chezmoi executable not found at $CHEZMOI_EXEC" >&2
    echo "This script requires chezmoi to be installed at that location." >&2
    exit 1
fi

for file in $TEMPLATE_FILES; do
  ((TEST_COUNT++))
  # Using printf for better control over newlines
  printf "  - Testing: %-80s ... " "$file"

  # Run the template execution within a zsh login shell to ensure the environment
  # is loaded correctly. Redirect stderr to stdout to capture any errors.
  if output=$(zsh -lc "$CHEZMOI_EXEC execute-template '$file'" 2>&1); then
    echo "✅ OK"
  else
    echo "❌ FAILED"
    FAILED_TEMPLATES+=("$file")
    # Optionally print the error output for immediate feedback
    # echo "    Error: $output"
  fi
done

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
