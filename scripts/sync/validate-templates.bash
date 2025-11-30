#!/usr/bin/env bash

# validate-templates.bash — Validate Chezmoi template includes
#
# This script scans Chezmoi templates and scripts for `{{ include ... }}` and
# `{{ includeTemplate ... }}` directives, verifying that the referenced files
# actually exist in the source directory.
#
# It checks:
# 1. Recursively in .chezmoiscripts/
# 2. Recursively in the root for *.tmpl files

set -euo pipefail

SCRIPT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd -P)
REPO_ROOT=$(CDPATH='' cd -- "$SCRIPT_DIR/../.." && pwd -P)

# Defaults
CHEZMOI_ROOT_DEFAULT="$REPO_ROOT/home/current"
CHEZMOI_ROOT="${CHEZMOI_ROOT:-$CHEZMOI_ROOT_DEFAULT}"
CHEZMOI_TEMPLATES_ROOT="${CHEZMOI_TEMPLATES_ROOT:-$CHEZMOI_ROOT/.chezmoitemplates}"

DRY_RUN=0
VERBOSE=0
QUIET=0
FILES_CHECKED=0
FILES_WITH_ERRORS=0
TOTAL_ERRORS=0

usage() {
  cat <<USAGE
Usage: $(basename "$0") [options]

Validates 'include' and 'includeTemplate' directives in Chezmoi templates.

Options:
  --root <dir>            Chezmoi source root directory (default: $CHEZMOI_ROOT_DEFAULT).
  --dry-run               (No-op for this script, as it is read-only, but included for consistency).
  --verbose, -v           Show checked files.
  --quiet, -q             Suppress non-error output.
  -h, --help              Show this help message.

Checks:
  - {{ include "path/to/file" }} -> Checks if \$CHEZMOI_ROOT/path/to/file exists.
  - {{ includeTemplate "path/to/file" }} -> Checks if \$CHEZMOI_ROOT/.chezmoitemplates/path/to/file exists.
USAGE
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --root) CHEZMOI_ROOT="$2"; shift ;;
    --dry-run) DRY_RUN=1 ;;
    --verbose|-v) VERBOSE=1 ;;
    --quiet|-q) QUIET=1 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "error: unknown arg: $1" >&2; usage; exit 2 ;;
  esac
  shift
done

# Update templates root if root changed
CHEZMOI_TEMPLATES_ROOT="${CHEZMOI_ROOT}/.chezmoitemplates"

log() { [ "$QUIET" -eq 0 ] && printf '%s\n' "$*"; }
vlog() { [ "$VERBOSE" -eq 1 ] && printf '%s\n' "$*"; }
err() { printf 'error: %s\n' "$*" >&2; }

if [ ! -d "$CHEZMOI_ROOT" ]; then
  err "Chezmoi root not found: $CHEZMOI_ROOT"
  exit 1
fi

check_file() {
  local file="$1"
  local rel_file="${file#$CHEZMOI_ROOT/}"
  local has_error=0

  vlog "Checking: $rel_file"
  FILES_CHECKED=$((FILES_CHECKED+1))

  # Extract includes
  # We look for {{ include "..." }} and {{ includeTemplate "..." }}
  # We use grep to find lines, then sed/awk to extract paths.
  # Note: This is a simple regex and might miss complex cases or multiline, but covers standard usage.

  local includes
  includes=$(grep -oE '\{\{\s*(include|includeTemplate)\s+"[^"]+"\s*' "$file" || true)

  if [ -z "$includes" ]; then
    return
  fi

  while IFS= read -r match; do
    [ -z "$match" ] && continue

    local type path full_path target_desc

    if [[ "$match" =~ includeTemplate ]]; then
      type="includeTemplate"
      path=$(echo "$match" | sed -E 's/.*includeTemplate\s+"([^"]+)".*/\1/')
      full_path="$CHEZMOI_TEMPLATES_ROOT/$path"
      target_desc=".chezmoitemplates/$path"
    else
      type="include"
      path=$(echo "$match" | sed -E 's/.*include\s+"([^"]+)".*/\1/')
      full_path="$CHEZMOI_ROOT/$path"
      target_desc="$path"
    fi

    if [ ! -f "$full_path" ]; then
      # Try to be helpful: check if it exists with .tmpl extension if not specified?
      # But usually include refers to the exact filename.

      echo "  [FAIL] $rel_file: $type \"$path\" -> missing $target_desc"
      has_error=1
      TOTAL_ERRORS=$((TOTAL_ERRORS+1))
    else
      vlog "  [OK] $type \"$path\""
    fi

  done <<< "$includes"

  if [ "$has_error" -eq 1 ]; then
    FILES_WITH_ERRORS=$((FILES_WITH_ERRORS+1))
  fi
}

log "Scanning $CHEZMOI_ROOT..."

# 1. Scan .chezmoiscripts recursively
if [ -d "$CHEZMOI_ROOT/.chezmoiscripts" ]; then
  while IFS= read -r -d '' f; do
    check_file "$f"
  done < <(find "$CHEZMOI_ROOT/.chezmoiscripts" -type f -print0)
fi

# 2. Scan *.tmpl files in root recursively (excluding .chezmoiscripts which we just did, and .git)
# We use -path to exclude .chezmoiscripts to avoid double counting if we want,
# but find's -prune is better.
while IFS= read -r -d '' f; do
  check_file "$f"
done < <(find "$CHEZMOI_ROOT" -type d \( -name .git -o -name .chezmoiscripts \) -prune -o -type f -name "*.tmpl" -print0)

log "--- Summary ---"
log "Files checked: $FILES_CHECKED"
if [ "$TOTAL_ERRORS" -gt 0 ]; then
  log "Files with errors: $FILES_WITH_ERRORS"
  log "Total missing includes: $TOTAL_ERRORS"
  exit 1
else
  log "No errors found."
  exit 0
fi
