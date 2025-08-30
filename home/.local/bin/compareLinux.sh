#!/usr/bin/env bash

# Compare local Linux filesystem to a remote host using rsync (dry-run by default).
#
# Default behavior replicates the original one-liner:
#   rsync --dry-run --itemize-changes --checksum --archive \
#         --exclude=/var/log --exclude=/var/cache --exclude=/dev \
#         / HOST:/
#
# Modernized to add safety, flags, and help. No functionality removed; defaults preserved.

set -euo pipefail
IFS=$'\n\t'

print_help() {
  cat <<'EOF'
Usage: compareLinux.sh [options] <host>

Compare local root (/) against a remote host using rsync. Dry-run by default.

Positional arguments:
  host                    Target host (will sync to user@host:remote-path)

Options:
  --go                    Execute (not a dry-run). Default is dry-run.
  --remote-path PATH      Remote destination path. Default: '/'
  --port PORT             SSH port. Example: 2222
  --user USER             SSH username. Example: root
  --ssh OPTS              Extra SSH options string passed to -e ssh (quoted).
  --exclude PATH          Add an rsync --exclude pattern (can be repeated).
  --exclude-file FILE     Add excludes from FILE (one pattern per line).
  --extra OPTS            Extra rsync options string appended at the end.
  -v, --verbose           Increase verbosity (prints the rsync command).
  -h, --help              Show this help and exit.

Defaults kept for backward compatibility:
  --dry-run --itemize-changes --checksum --archive
  --exclude=/var/log --exclude=/var/cache --exclude=/dev --exclude=/proc --exclude=/sys --exclude=/run --exclude=/tmp
EOF
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || { echo "Error: Required command '$1' not found" >&2; exit 127; }
}

# Preconditions
require_cmd rsync
require_cmd ssh

if [[ ${OSTYPE:-} != linux* ]] && [[ "$(uname -s 2>/dev/null || true)" != "Linux" ]]; then
  echo "Warning: Intended for Linux. Proceeding anyway..." >&2
fi

DRY_RUN=1
REMOTE_PATH="/"
REMOTE_USER=""
SSH_PORT=""
SSH_EXTRA=""
EXTRA_OPTS=""
VERBOSE=0

# Default rsync flags and excludes preserved
RSYNC_FLAGS=(--dry-run --itemize-changes --checksum --archive)
DEFAULT_EXCLUDES=(
  /var/log
  /var/cache
  /dev
  /proc
  /sys
  /run
  /tmp
)
EXCLUDE_ARGS=()

while (( "$#" )); do
  case "$1" in
    --go)
      DRY_RUN=0; shift ;;
    --remote-path)
      [[ $# -ge 2 ]] || { echo "Error: --remote-path requires a value" >&2; exit 2; }
      REMOTE_PATH="$2"; shift 2 ;;
    --port)
      [[ $# -ge 2 ]] || { echo "Error: --port requires a value" >&2; exit 2; }
      SSH_PORT="$2"; shift 2 ;;
    --user)
      [[ $# -ge 2 ]] || { echo "Error: --user requires a value" >&2; exit 2; }
      REMOTE_USER="$2"; shift 2 ;;
    --ssh)
      [[ $# -ge 2 ]] || { echo "Error: --ssh requires a value" >&2; exit 2; }
      SSH_EXTRA="$2"; shift 2 ;;
    --exclude)
      [[ $# -ge 2 ]] || { echo "Error: --exclude requires a value" >&2; exit 2; }
      EXCLUDE_ARGS+=("--exclude=$2"); shift 2 ;;
    --exclude-file)
      [[ $# -ge 2 ]] || { echo "Error: --exclude-file requires a value" >&2; exit 2; }
      if [[ -f "$2" ]]; then
        while IFS= read -r line; do
          [[ -z "$line" || "$line" =~ ^\s*# ]] && continue
          EXCLUDE_ARGS+=("--exclude=$line")
        done <"$2"
      else
        echo "Error: exclude file not found: $2" >&2; exit 2
      fi
      shift 2 ;;
    --extra)
      [[ $# -ge 2 ]] || { echo "Error: --extra requires a value" >&2; exit 2; }
      EXTRA_OPTS+=" $2"; shift 2 ;;
    -v|--verbose)
      VERBOSE=$((VERBOSE+1)); shift ;;
    -h|--help)
      print_help; exit 0 ;;
    --)
      shift; break ;;
    -*)
      echo "Error: Unknown option: $1" >&2; echo; print_help; exit 2 ;;
    *)
      # First non-option is the host
      HOST="$1"; shift; break ;;
  esac
done

# If additional args remain after '--', treat first as host
if [[ -z ${HOST:-} ]] && (( $# > 0 )); then
  HOST="$1"; shift || true
fi

if [[ -z ${HOST:-} ]]; then
  echo "Error: host is required" >&2
  echo
  print_help
  exit 2
fi

# Compose SSH command
SSH_CMD=(ssh)
if [[ -n "$SSH_PORT" ]]; then
  SSH_CMD+=( -p "$SSH_PORT" )
fi
if [[ -n "$SSH_EXTRA" ]]; then
  # shellcheck disable=SC2206
  SSH_CMD+=( ${SSH_EXTRA} )
fi

# Apply default excludes unless user explicitly passed any excludes for those paths.
if (( ${#EXCLUDE_ARGS[@]} == 0 )); then
  for p in "${DEFAULT_EXCLUDES[@]}"; do
    EXCLUDE_ARGS+=("--exclude=$p")
  done
fi

# Adjust dry-run flag
if (( DRY_RUN == 0 )); then
  # Remove --dry-run if present
  NEW_FLAGS=()
  for f in "${RSYNC_FLAGS[@]}"; do
    [[ "$f" == "--dry-run" ]] && continue
    NEW_FLAGS+=("$f")
  done
  RSYNC_FLAGS=("${NEW_FLAGS[@]}")
fi

REMOTE_PREFIX="${REMOTE_USER:+${REMOTE_USER}@}${HOST}:${REMOTE_PATH}"

CMD=( rsync "${RSYNC_FLAGS[@]}" "${EXCLUDE_ARGS[@]}" -e "${SSH_CMD[*]}" / "${REMOTE_PREFIX}" )

if [[ -n "$EXTRA_OPTS" ]]; then
  # shellcheck disable=SC2206
  CMD=( ${CMD[@]} ${EXTRA_OPTS} )
fi

if (( VERBOSE > 0 )); then
  echo "+ ${CMD[*]}" >&2
fi

exec "${CMD[@]}"
