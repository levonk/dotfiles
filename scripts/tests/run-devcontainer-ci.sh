#!/usr/bin/env bash
# Timeboxed runner for devcontainer CI tests
# Usage: scripts/tests/run-devcontainer-ci.sh [timeout_secs]
set -euo pipefail
TIMEOUT_SECS=${1:-360}
COMPOSE_FILE=".devcontainer/docker-compose.yml"
SERVICE="dotfiles-ci"

# Move to repo root from scripts/tests/
cd "$(dirname "$0")/../.."

echo "⏳ Running $SERVICE with timeout ${TIMEOUT_SECS}s..."
# Ensure docker compose is available
if command -v docker-compose >/dev/null 2>&1; then
  COMPOSE_CMD=(docker-compose -f "$COMPOSE_FILE")
else
  # Docker Compose V2 plugin
  COMPOSE_CMD=(docker compose -f "$COMPOSE_FILE")
fi

# Run the CI service with a hard timeout; pass an internal per-test timeout too
export DEV_TEST_TIMEOUT_SECS=${DEV_TEST_TIMEOUT_SECS:-90}

set +e
timeout --signal=KILL "${TIMEOUT_SECS}"s "${COMPOSE_CMD[@]}" run --rm \
  -e DEV_TEST_TIMEOUT_SECS="$DEV_TEST_TIMEOUT_SECS" \
  "$SERVICE"
RC=$?
set -e

if [ $RC -eq 124 ] || [ $RC -eq 137 ]; then
  echo "⏳ Container run timed out after ${TIMEOUT_SECS}s (rc=$RC)."
  exit 124
fi

exit $RC
