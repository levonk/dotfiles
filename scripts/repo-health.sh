#!/usr/bin/env bash
#
# repo-health.sh — Run repo health checks (lint, format, tests, sanity)
#
# Purpose:
#   Encapsulates common repository checks into a single script so day-to-day
#   usage doesn't spam the terminal with a wall of commands. Safe to run
#   repeatedly; read-only by default.
#
# Shell support:
#   bash (preferred); should work with POSIX shells if bash is not available.
#
# Security:
#   - No network calls.
#   - Read-only checks; does not mutate repository state.
#
# Usage:
#   scripts/repo-health.sh [--quick] [--no-shellcheck] [--no-shfmt] [--no-bats] [--no-json] [--no-yaml]
#
# Examples:
#   # Full checks
#   scripts/repo-health.sh
#   # Quicker pass (skips bats)
#   scripts/repo-health.sh --quick
#
set -euo pipefail

# Resolve repo root (script can be run from anywhere inside repo)
SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)
REPO_ROOT=$(cd "$SCRIPT_DIR/.." && pwd -P)
cd "$REPO_ROOT"

QUICK=0
DO_SHELLCHECK=1
DO_SHFMT=1
DO_BATS=1
DO_JSON=1
DO_YAML=1

for arg in "$@"; do
  case "$arg" in
    --quick) QUICK=1; DO_BATS=0 ;;
    --no-shellcheck) DO_SHELLCHECK=0 ;;
    --no-shfmt) DO_SHFMT=0 ;;
    --no-bats) DO_BATS=0 ;;
    --no-json) DO_JSON=0 ;;
    --no-yaml) DO_YAML=0 ;;
    -h|--help)
      sed -n '1,60p' "$0"; exit 0 ;;
    *) echo "warn: unknown flag: $arg" >&2 ;;
  esac
done

log() { printf "\n== %s ==\n" "$*"; }
check_bin() { command -v "$1" >/dev/null 2>&1; }

log "Tool availability"
for b in shellcheck shfmt bats jq rg python; do
  if check_bin "$b"; then
    ver=$({ "$b" --version 2>/dev/null || "$b" -V 2>/dev/null || "$b" -v 2>/dev/null || true; } | head -n1)
    printf "> %-12s %s\n" "$b:" "${ver:-available}"
  else
    printf "> %-12s not installed\n" "$b:"
  fi
done

log "git status (porcelain)"
git status --untracked-files=all --porcelain || true

# Collect shell files
FILES=$(git ls-files | grep -E '(\.sh$|/bin/|/util/|/env/|/aliases/)' || true)

# shellcheck
if [ "$DO_SHELLCHECK" -eq 1 ] && [ -n "$FILES" ] && check_bin shellcheck; then
  log "shellcheck"
  # -x to follow source; do not fail the whole script, just report
  shellcheck -x $FILES || true
fi

# shfmt (diff only)
if [ "$DO_SHFMT" -eq 1 ] && [ -n "$FILES" ] && check_bin shfmt; then
  log "shfmt diff (no changes)"
  shfmt -d $FILES || true
fi

# bats tests
if [ "$DO_BATS" -eq 1 ] && check_bin bats && [ -d tests ]; then
  log "bats tests"
  # Use recursive run; allow failures to be reported without exiting
  bats -r tests || true
fi

# JSON sanity
if [ "$DO_JSON" -eq 1 ] && check_bin jq; then
  log "JSON sanity"
  if git ls-files "*.json" | xargs -r -n1 jq -e . >/dev/null; then
    echo "JSON OK"
  else
    echo "JSON issues"; true
  fi
fi

# YAML sanity (requires PyYAML)
if [ "$DO_YAML" -eq 1 ] && check_bin python; then
  if python - <<'PY' | grep -q yes; then
try:
  import yaml  # type: ignore
  print('yes')
except Exception:
  print('no')
PY
    log "YAML sanity"
    git ls-files "*.yml" "*.yaml" | xargs -r -n1 python - <<'PY'
import sys, yaml
for p in sys.argv[1:]:
    yaml.safe_load(open(p))
PY
    echo "YAML OK"
  else
    echo "> PyYAML not installed; skipping YAML sanity"
  fi
fi

# Ripgrep scan for common flags
if check_bin rg; then
  log "ripgrep common flags"
  rg -nEI 'FIXME|TODO|(set -euo pipefail).*#?\s*shellcheck|command not found|No such file or directory' || true
fi

log "Done"
