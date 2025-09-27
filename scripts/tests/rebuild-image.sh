#!/usr/bin/env bash
# =============================================================================
# scripts/tests/rebuild-image.sh
#
# Rebuilds the devcontainer image with layer-aware caching.
# - Ensures the 'dotfiles-base' stage is built and cached.
# - Rebuilds the 'dotfiles-test-env' stage without cache, but reuses the
#   cached base layer.
#
# This allows for a clean user environment without rebuilding system deps.
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")/.."
DEVCONTAINER_DIR="$REPO_ROOT/.devcontainer"

COMPOSE_FILE="$DEVCONTAINER_DIR/docker-compose.yml"
SERVICE="${1:-dotfiles-ci}"

log() { echo "[rebuild] $*"; }
err() { echo "[rebuild-error] $*" >&2; }

# Detect docker compose command
detect_compose_cmd() {
  if command -v docker >/dev/null 2>&1 && docker compose version >/dev/null 2>&1; then
    echo "docker compose"
  elif command -v docker-compose >/dev/null 2>&1; then
    echo "docker-compose"
  else
    err "Neither 'docker-compose' nor 'docker compose' command found."
    return 1
  fi
}

COMPOSE_CMD="$(detect_compose_cmd)"

# --- Staged Build Logic ---
# This script uses a two-step process to force a rebuild of the user layer
# while keeping the base layer cached.

# 1. Build and Tag the Base Stage (if it doesn't exist)
# We check if the base image already exists. If not, we build it.
# This prevents rebuilding the base layer on every run.
BASE_IMAGE_TAG="dotfiles-base:latest"
FORCE_REBUILD_BASE="${FORCE_REBUILD_BASE:-0}"

if [[ "$FORCE_REBUILD_BASE" = "1" ]] || ! docker image inspect "$BASE_IMAGE_TAG" >/dev/null 2>&1; then
  if [[ "$FORCE_REBUILD_BASE" = "1" ]]; then
    log "Step 1: Forcing rebuild of base image stage ('dotfiles-base')..."
  else
    log "Step 1: Base image not found. Building and caching base image stage ('dotfiles-base')..."
  fi
  docker build --target dotfiles-base -t "$BASE_IMAGE_TAG" "$DEVCONTAINER_DIR"
else
  log "Step 1: Using existing cached base image ('$BASE_IMAGE_TAG')."
fi

# 2. Build the Final Stage with --no-cache
# Now, we build the final service image using docker-compose. We pass two critical flags:
#   --no-cache: This tells Docker to ignore the cache for this build run.
#   --build-arg TEST_ENV_BASE_IMAGE=...: This explicitly tells the Dockerfile to use
#     the stable tag we just created as its base image.
#
# The result is that the 'FROM' instruction in the final stage resolves to our
# cached base image, while all subsequent steps in that stage are run from scratch.
log "Step 2: Rebuilding final image for service '$SERVICE' using cached base..."
$COMPOSE_CMD -f "$COMPOSE_FILE" build --no-cache \
  --build-arg "TEST_ENV_BASE_IMAGE=$BASE_IMAGE_TAG" \
  "$SERVICE"

log "Image rebuild complete for service '$SERVICE'."
