#!/usr/bin/env bash
# ============================================================================
# rmlint convenience wrapper
# ============================================================================
# Purpose:
#   * Ensure rmlint is available (install via common package managers when missing)
#   * Run rmlint against a provided start directory (defaults to /)
#   * Emit pretty + summary output to the console while also generating
#     JSON and shell remediation files
#   * Provide helpful usage guidance via --help/--usage flags
#
# Usage:
#   executiable_rmlint-runner.sh [START_PATH]
#   executiable_rmlint-runner.sh --help
#
# Environment:
#   RMLINT_OUTPUT_DIR  Optional override for report directory (default: ~/.cache/rmlint)
#
# See: https://github.com/sahib/rmlint
# ============================================================================

set -euo pipefail

SCRIPT_NAME="executiable_rmlint-runner.sh"
DEFAULT_ROOT="/"
RMLINT_BIN="rmlint"

usage() {
  cat <<"EOF"
Usage: executiable_rmlint-runner.sh [START_PATH]

Runs rmlint from START_PATH (default: /), installs rmlint if missing, and
generates:
  * Pretty + summary output to the console (with progress bar)
  * JSON report saved to the output directory
  * Shell cleanup script saved to the output directory

Options:
  -h, --help, --usage   Show this message

Environment:
  RMLINT_OUTPUT_DIR     Directory for JSON and shell outputs (default ~/.cache/rmlint)
EOF
}

log() {
  local level="$1"
  shift
  printf '[%s] %s\n' "$level" "$*"
}

die() {
  log "error" "$*"
  exit 1
}

ensure_rmlint() {
  if command -v "$RMLINT_BIN" >/dev/null 2>&1; then
    return
  fi

  log info "rmlint not found; attempting installation"
  if command -v apt-get >/dev/null 2>&1; then
    sudo apt-get update -y
    sudo apt-get install -y rmlint
  elif command -v dnf >/dev/null 2>&1; then
    sudo dnf install -y rmlint
  elif command -v pacman >/dev/null 2>&1; then
    sudo pacman -Sy --noconfirm rmlint
  elif command -v zypper >/dev/null 2>&1; then
    sudo zypper install -y rmlint
  elif command -v brew >/dev/null 2>&1; then
    brew install rmlint
  else
    die "Unable to install rmlint automatically. Please install it and re-run."
  fi

  if ! command -v "$RMLINT_BIN" >/dev/null 2>&1; then
    die "rmlint installation did not succeed or is not on PATH."
  fi
}

resolve_target_path() {
  local positional=()
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -h|--help|--usage)
        usage
        exit 0
        ;;
      --)
        shift
        positional+=("$@")
        break
        ;;
      -*)
        die "Unknown option: $1"
        ;;
      *)
        positional+=("$1")
        ;;
    esac
    shift || true
  done

  if [[ ${#positional[@]} -gt 1 ]]; then
    die "Too many positional arguments. Provide only the optional START_PATH."
  fi

  local target="$DEFAULT_ROOT"
  if [[ ${#positional[@]} -eq 1 ]]; then
    target="${positional[0]}"
  fi

  if [[ ! -d "$target" ]]; then
    die "Start path does not exist or is not a directory: $target"
  fi

  printf '%s\n' "$(realpath -m "$target")"
}

prepare_output_paths() {
  local base_dir="${RMLINT_OUTPUT_DIR:-$HOME/.cache/rmlint}"
  local timestamp
  timestamp="$(date +%Y%m%d-%H%M%S)"
  local prefix="$base_dir/rmlint-$timestamp"

  mkdir -p "$base_dir"
  printf '%s\n' "$prefix"
}

run_rmlint() {
  local start_path="$1"
  local prefix="$2"
  local json_path="${prefix}.json"
  local sh_path="${prefix}.sh"

  log info "Starting rmlint scan"
  log info "  start path : $start_path"
  log info "  json report: $json_path"
  log info "  shell script: $sh_path"

  "$RMLINT_BIN" "$start_path" \
    --progress=bar \
    -o "json:$json_path" \
    -o "sh:$sh_path" \
    -o "pretty:stdout" \
    -o "summary:stdout"

  log success "rmlint completed. JSON and shell outputs stored in $(dirname "$json_path")"
}

main() {
  local start_path
  start_path="$(resolve_target_path "$@")"

  ensure_rmlint
  local prefix
  prefix="$(prepare_output_paths)"
  run_rmlint "$start_path" "$prefix"
}

main "$@"
