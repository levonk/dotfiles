#!/usr/bin/env bash
set -euo pipefail

# ---
# clone-git.sh: Clone a git repository into a standardized directory tree under $PROJECT_HOME/gh/account/repo
# Supports any protocol (https, http, ssh, git, etc.) and passes extra arguments to git clone
# ---

# ---
# Usage/help
# ---
usage() {
  echo "Usage: $0 <git-url> [git-clone-args...]" >&2
  echo "  git-url: a valid git repository URL (supports https, http, ssh, git, etc.)" >&2
  echo "  Any additional arguments will be passed to git clone." >&2
  echo "  Example: $0 https://gitlab.com/levonk/apmw.git --depth 1" >&2
  exit 1
}

# ---
# Error checking
# ---
if [[ "${1:-}" == "-h" || "${1:-}" == "--help" || $# -lt 1 ]]; then
  usage
fi

# Check that PROJECT_HOME is set
if [[ -z "${PROJECT_HOME:-}" ]]; then
  echo "Error: PROJECT_HOME environment variable is not set." >&2
  exit 1
fi

# Check that git is available
if ! command -v git >/dev/null 2>&1; then
  echo "Error: git is not installed or not in PATH." >&2
  exit 2
fi

GIT_URL="$1"
shift
EXTRA_ARGS=("$@")  # Any additional arguments are passed to git clone

# ---
# Parse the git URL to extract account and repo names
# Supports:
#   - protocol://host/account/repo(.git)
#   - any path ending in /account/repo.git (e.g. SSH paths)
# ---
declare account repo url
if [[ "$GIT_URL" =~ ^[a-zA-Z0-9+.-]+://[^/]+/([^/]+)/([^/]+)(\.git)?$ ]]; then
  # Any protocol: protocol://host/account/repo(.git)
  account="${BASH_REMATCH[1]}"
  repo="${BASH_REMATCH[2]%.git}"
  url="$GIT_URL"
elif [[ "$GIT_URL" =~ \/([^/]+)/([^/]+)\.git$ ]]; then
  # Generic: any path ending in /account/repo.git like ssh paths
  account="${BASH_REMATCH[1]}"
  repo="${BASH_REMATCH[2]}"
  url="$GIT_URL"
else
  echo "Error: Invalid git URL format. Use protocol://host/account/repo(.git) or any SSH/URL ending in /account/repo.git" >&2
  exit 4
fi

# ---
# Create the target directory tree and cd into it
# Example: $PROJECT_HOME/gh/levonk/dotfiles
# ---
TARGET_DIR="$PROJECT_HOME/gh/$account/$repo"
mkdir -p "$TARGET_DIR"
cd "$TARGET_DIR"

# ---
# Clone the repository (unless already present)
# Pass any extra arguments to git clone
# ---
if [[ -d "$repo" ]]; then
  echo "Warning: Directory $repo already exists. Skipping clone." >&2
else
  git clone "${EXTRA_ARGS[@]}" "$url"
fi

cd "$repo"

# ---
# Validate that the result is a git repository
# ---
if [[ ! -d .git ]]; then
  echo "Error: $PWD is not a valid git repository." >&2
  exit 5
fi

# ---
# Success: ring the system bell and print the path
# ---
printf '\a'
echo "Clone complete: $PWD"
