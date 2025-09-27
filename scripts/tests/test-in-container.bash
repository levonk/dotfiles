#!/usr/bin/env bash
# =====================================================================
# scripts/tests/test_in_container.bash
# Headless wrapper to run dotfiles tests inside the devcontainer
# - Builds the test image if needed
# - Runs the CI-targeted service, which executes `.devcontainer/setup.sh`
#   and `scripts/tests/devcontainer-test.sh`
# - Exits non-zero if any test fails
# =====================================================================
set -euo pipefail

# Resolve repository root from this script's location
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Find repository root by walking up until we locate .devcontainer/docker-compose.yml or a .git directory
find_repo_root() {
  local d="$SCRIPT_DIR"
  while [[ "$d" != "/" ]]; do
    if [[ -f "$d/.devcontainer/docker-compose.yml" ]]; then
      echo "$d"; return 0
    fi
    if [[ -d "$d/.git" ]]; then
      echo "$d"; return 0
    fi
    d="$(dirname "$d")"
  done
  # Fallback: parent of script dir
  dirname "$SCRIPT_DIR"
}

REPO_ROOT="$(find_repo_root)"
COMPOSE_FILE="$REPO_ROOT/.devcontainer/docker-compose.yml"
SERVICE="${DEV_TEST_SERVICE:-dotfiles-ci}"
# --- Build Control Flags ---
# Default behavior: Rebuild the user layer on each run (REBUILD_USER=1).
# This provides a clean user environment without reinstalling base dependencies.
#
# Flags to modify behavior:
#   --no-rebuild: Skips all build steps and uses the fully cached image.
#   --rebuild:    Forces a full, non-cached rebuild of the entire image.
REBUILD=0              # Default: Don't do a full rebuild.
REBUILD_BASE=0           # Default: Don't rebuild the base layer.
REBUILD_USER=1         # Default: Rebuild the user layer.
CLEAN=0                # Default: Don't clean volumes.

# Prepare a host-side logs directory to bind-mount into the container.
# Default: <repo>/temp/logs -> /temp/logs (rw). Allow override via DEV_TEST_HOST_LOG_DIR.
HOST_LOG_DIR_DEFAULT="$REPO_ROOT/temp/logs"
HOST_LOG_DIR="${DEV_TEST_HOST_LOG_DIR:-$HOST_LOG_DIR_DEFAULT}"
CONTAINER_LOG_DIR="/temp/logs"

# Ensure host log dir exists and is writable by any UID (avoid permission mismatches inside container).
mkdir -p "$HOST_LOG_DIR"
chmod 0777 "$HOST_LOG_DIR" 2>/dev/null || true

err() { echo "[error] $*" >&2; }
log() { echo "[wrapper] $*"; }

usage() {
  cat <<USAGE
Usage: $(basename "$0") [options]

Runs the devcontainer-based test suite headlessly.
Default behavior is to rebuild the user layer while using the cached base image.

Options:
  --service <name>    Compose service to run (default: dotfiles-ci)
  --no-rebuild        Skip all rebuild steps and use the fully cached image.
  --rebuild-base      Force a rebuild of the base image layer.
  --rebuild           Force a full, non-cached rebuild of the entire image.
  --clean             Remove all Docker volumes before running to ensure a clean state.
  -h, --help          Show this help

Environment overrides:
  DEV_TEST_SERVICE    Service name (default: dotfiles-ci)
USAGE
}

# Parse simple flags
while [[ $# -gt 0 ]]; do
  case "$1" in
    --service)
      shift; [[ $# -gt 0 ]] || { err "--service requires a value"; exit 2; }
      SERVICE="$1"; shift ;;
    --rebuild)
      REBUILD=1; REBUILD_USER=0; shift ;;
    --rebuild-base)
      REBUILD_BASE=1; shift ;;
    --no-rebuild)
      REBUILD_USER=0; shift ;;
    --clean)
      CLEAN=1; shift ;;
    -h|--help)
      usage; exit 0 ;;
    *)
      err "Unknown argument: $1"; usage; exit 2 ;;
  esac
done

# Verify compose file exists
if [[ ! -f "$COMPOSE_FILE" ]]; then
  err "Compose file not found: $COMPOSE_FILE"
  exit 1
fi

# Detect docker compose command (prefer plugin: `docker compose`)
detect_compose_cmd() {
  if command -v docker >/dev/null 2>&1 && docker compose version >/dev/null 2>&1; then
    echo "docker compose"
    return 0
  fi
  if command -v docker-compose >/dev/null 2>&1; then
    echo "docker-compose"
    return 0
  fi
  return 1
}

if ! COMPOSE_CMD="$(detect_compose_cmd)"; then
  err "Neither 'docker-compose' nor 'docker compose' command found. Please install one."
  exit 1
fi

log "Using compose: $COMPOSE_CMD"
log "Compose file: $COMPOSE_FILE"
if [[ "$CLEAN" = "1" ]]; then
  log "Cleaning Docker environment (--clean requested)..."
  # The COMPOSE_CMD is already detected at this point.
  $COMPOSE_CMD -f "$COMPOSE_FILE" down -v --remove-orphans
  log "Docker environment cleaned."
fi

# Rebuild logic based on flags.
# The order of checks is important: --rebuild takes precedence.
if [[ "$REBUILD" = "1" ]]; then
  log "Performing a full, non-cached rebuild for service '$SERVICE' (--rebuild specified)..."
  $COMPOSE_CMD -f "$COMPOSE_FILE" build --no-cache "$SERVICE"
elif [[ "$REBUILD_USER" = "1" ]]; then
  log "Rebuilding user layer for service '$SERVICE' (default behavior)..."
  log "--> To skip this step, use the --no-rebuild flag."
  FORCE_REBUILD_BASE=$REBUILD_BASE "$SCRIPT_DIR/rebuild-image.sh" "$SERVICE"
else
  log "Using fully cached image (--no-rebuild specified)."
fi

# Run the CI service headlessly (removes container after run)
log "Running tests in container..."
# shellcheck disable=SC2086
$COMPOSE_CMD -f "$COMPOSE_FILE" run --rm \
  -v "$HOST_LOG_DIR:$CONTAINER_LOG_DIR:rw" \
  "$SERVICE" /workspace/scripts/tests/run-ci-tests.sh
RC=$?

if [[ $RC -eq 0 ]]; then
  log "Tests completed successfully."
else
  err "Tests failed with exit code $RC"
fi
exit $RC
