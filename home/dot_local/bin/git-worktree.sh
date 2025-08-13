#!/usr/bin/env bash
set -euo pipefail

# ---
# git-worktree.sh: Create a git worktree for a feature branch in a standardized directory
# Usage: git-worktree.sh <feature-id> [additional git worktree args]
#
# - Requires $PROJECT_HOME and $USERNAME to be set
# - Copies .env and selected files/dirs from main repo if present
# - Switches to the new worktree directory
# ---

# List of files/directories to copy if missing in new worktree
COPY_ITEMS=(.windsurf .instrumental .agent_os .claude .cursof .vscode .kiro)

# ---
# Usage/help
# ---
usage() {
  echo "Usage: $0 <feature-id> [git-worktree-args...]" >&2
  echo "  feature-id: short, Linux-path-safe identifier for the worktree (no spaces, no slashes)" >&2
  echo "  Example: $0 cool-feature --track -b cool-feature origin/main" >&2
  exit 1
}

# ---
# Error checking
# ---
if [[ "${1:-}" == "-h" || "${1:-}" == "--help" || $# -lt 1 ]]; then
  usage
fi

if [[ -z "${PROJECT_HOME:-}" ]]; then
  echo "Error: PROJECT_HOME environment variable is not set." >&2
  exit 2
fi
if [[ -z "${USERNAME:-}" ]]; then
  echo "Error: USERNAME environment variable is not set." >&2
  exit 3
fi
if ! command -v git >/dev/null 2>&1; then
  echo "Error: git is not installed or not in PATH." >&2
  exit 4
fi

FEATURE_ID="$1"
shift
EXTRA_ARGS=("$@")

# Validate feature-id: must be Linux-path-safe (no spaces, no slashes, only safe chars)
if [[ ! "$FEATURE_ID" =~ ^[a-zA-Z0-9._-]+$ ]]; then
  echo "Error: feature-id must be a short, Linux-path-safe string (letters, numbers, ., _, -)." >&2
  exit 5
fi

# ---
# Find the top-level git repo (assume script is run from inside repo)
# ---
REPO_ROOT=$(git rev-parse --show-toplevel)
if [[ -z "$REPO_ROOT" ]]; then
  echo "Error: Could not find the root of the git repository." >&2
  exit 6
fi

# Extract account and repo from repo root path
# Expecting .../$PROJECT_HOME/gh/<account>/<repo>/[repo]
REPO_PARENT=$(basename "$(dirname "$REPO_ROOT")")
REPO_NAME=$(basename "$REPO_ROOT")
REPO_ACCOUNT=$(basename "$(dirname "$(dirname "$REPO_ROOT")")")

# Compose worktree path
WORKTREE_PATH="$PROJECT_HOME/gh/$REPO_ACCOUNT/$REPO_NAME/wt-${USERNAME}/${FEATURE_ID}"

# ---
# Create the worktree and branch in one step
# ---
BRANCH_NAME="wt/$USERNAME/$FEATURE_ID"
git worktree add -b "$BRANCH_NAME" "${EXTRA_ARGS[@]}" "$WORKTREE_PATH"

# ---
# Copy .env if present in main repo dir
# ---
if [[ -f "$REPO_ROOT/$REPO_NAME/.env" ]]; then
  cp "$REPO_ROOT/$REPO_NAME/.env" "$WORKTREE_PATH/" || true
fi

# ---
# Copy selected files/dirs if present in repo and missing in worktree
# ---
for item in "${COPY_ITEMS[@]}"; do
  if [[ -e "$REPO_ROOT/$REPO_NAME/$item" && ! -e "$WORKTREE_PATH/$item" ]]; then
    cp -r "$REPO_ROOT/$REPO_NAME/$item" "$WORKTREE_PATH/"
  fi
fi

# ---
# Switch to the new worktree
# ---
cd "$WORKTREE_PATH"
echo "Switched to new worktree: $WORKTREE_PATH"

# ---
# Verify we are on the expected branch
# ---
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
if [[ "$CURRENT_BRANCH" != "$BRANCH_NAME" ]]; then
  echo "Error: Expected to be on branch '$BRANCH_NAME' but found '$CURRENT_BRANCH'." >&2
  exit 10
fi

echo "Now on branch: $BRANCH_NAME"
