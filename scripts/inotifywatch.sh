#!/usr/bin/env bash
TARGET_DIRS="$HOME/.ssh $HOME/.local/share $HOME/.config"

echo "Monitoring permission changes in: $TARGET_DIRS"
inotifywait -m -e attrib --format '%w%f %e' "$TARGET_DIRS" | while read -r FILE EVENT; do
    # Try to get current mode (permissions) of the path; for deleted paths, stat will fail
    MODE=$(stat -c '%a' "$FILE" 2>/dev/null || echo "?")
    TYPE="file"
    [ -d "$FILE" ] && TYPE="dir"

    # Only keep directory ATTRIB events for the root dirs to avoid noise
    ROOT_SSH="$HOME/.ssh"
    ROOT_CFG="$HOME/.config"
    ROOT_SHARE="$HOME/.local/share"
    FILE_NORM="${FILE%/}"
    case "$EVENT" in
      *ISDIR*) ;; # directory event
      *) continue;;
    esac
    if [ "$FILE_NORM" != "$ROOT_SSH" ] && [ "$FILE_NORM" != "$ROOT_CFG" ] && [ "$FILE_NORM" != "$ROOT_SHARE" ]; then
      continue
    fi
    TS=$(date '+%Y-%m-%d %H:%M:%S')
    echo "ATTRIB: $FILE (type=$TYPE mode=$MODE event=$EVENT) at $TS"

    # Snapshot processes touching this path (best effort, read-only)
    echo "--- SNAPSHOT BEGIN [$TS] $FILE ---"
    if command -v lsof >/dev/null 2>&1; then
      # If it's a directory, use +D; otherwise use -- to avoid deep recursion cost
      if [ "$TYPE" = "dir" ]; then
        lsof +D "$FILE" 2>/dev/null | head -n 100 || true
      else
        lsof -- "$FILE" 2>/dev/null | head -n 100 || true
      fi
    else
      echo "lsof not available"
    fi

    fuser -v "$FILE" 2>/dev/null || true

    # /proc scan to find PIDs with FDs under the path
    # (kept short to avoid excessive load)
    {
      for pid in /proc/[0-9]*; do
        bpid=$(basename "$pid")
        # Limit per-PID FD scan to avoid heavy load
        for fd in "$pid"/fd/*; do
          target=$(readlink -f "$fd" 2>/dev/null || true)
          case "$target" in
            "$FILE"|"$FILE"/*)
              cmd=$(tr -d '\0' </proc/"$bpid"/cmdline 2>/dev/null || true)
              echo "PROC: PID=$bpid CMD=$cmd"
              break
              ;;
          esac
        done
      done
    } | sort -u | head -n 200
    echo "--- SNAPSHOT END [$TS] $FILE ---"

    # Note: inotify ATTRIB includes permission, ownership, timestamps, and xattr changes.
    # For process attribution, combine with auditd (ausearch) if needed.
done