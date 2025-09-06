#!/usr/bin/env bash
set -euo pipefail

export PATH="$HOME/.local/bin:$PATH"

_DANGER_LOG_FILE="/tmp/danger-scratch-apply.log"
_DANGER_STRACE_FILE="/tmp/danger-chezmoi-apply-real.strace.log"
APPLY_TIMEOUT_SECS="${DANGER_APPLY_TIMEOUT_SECS:-600}"
_DB_PATH="${XDG_CONFIG_HOME:-$HOME/.config}/chezmoi/chezmoistate.boltdb"

# CLI flags
#  --no-git-checks : skip git cleanliness preflight (sets DANGER_SKIP_GIT_PREFLIGHT=1)
for _arg in "$@"; do
  case "$_arg" in
    --no-git-checks)
      export DANGER_SKIP_GIT_PREFLIGHT=1
      echo "[preflight] --no-git-checks passed; skipping git cleanliness checks (DANGER_SKIP_GIT_PREFLIGHT=1)" | tee -a "$_DANGER_LOG_FILE"
      ;;
  esac
done

# Small helpers
command_exists() { command -v "$1" >/dev/null 2>&1; }

# Determine if running in an interactive terminal
is_interactive() {
  [ -t 0 ] || [ -t 1 ] || [ -t 2 ] || [ -r /dev/tty ]
}

# Interactive pause helper: prefers /dev/tty to avoid issues when stdout is piped
pause_interactive() {
  local note="${1:-Press Enter to continue, or Ctrl+C to abort}"; local ans=""
  if [ -t 0 ] || [ -r /dev/tty ]; then
    # Print the note to both stderr and log for visibility
    echo "[preflight] $note" | tee -a "$_DANGER_LOG_FILE" >&2
    if [ -r /dev/tty ]; then
      # Read directly from the terminal even if stdin is redirected
      read -r -p "[preflight] $note > " ans </dev/tty || true
    else
      read -r -p "[preflight] $note > " ans || true
    fi
  fi
}

# Preflight: detect existing chezmoi processes and potential state DB locks
preflight_chezmoi_lock_check() {
    local skip_preflight
    skip_preflight="${DEV_TEST_SKIP_PREFLIGHT:-0}"
    [ "$skip_preflight" = "1" ] && { echo "[preflight] Skipping chezmoi lock check (DEV_TEST_SKIP_PREFLIGHT=1)" | tee -a "$_DANGER_LOG_FILE"; return 0; }

    local db_path
    db_path="$HOME/.config/chezmoi/chezmoistate.boltdb"

    echo "[preflight] Checking for running chezmoi processes and locks" | tee -a "$_DANGER_LOG_FILE"

    local procs=""
    if command_exists pgrep; then
        procs=$(pgrep -a chezmoi || true)
        if [ -n "$procs" ]; then
            echo "[preflight] Detected running chezmoi processes:" | tee -a "$_DANGER_LOG_FILE"
            echo "$procs" | tee -a "$_DANGER_LOG_FILE"
            if [ -f "$_DB_PATH" ]; then
                echo "[preflight] Inspecting persistent state DB: $_DB_PATH" | tee -a "$_DANGER_LOG_FILE"
                ls -l -- "$_DB_PATH" | tee -a "$_DANGER_LOG_FILE"
                if command_exists lsof; then
                    echo "[preflight] lsof holders for $_DB_PATH (first 80 lines):" | tee -a "$_DANGER_LOG_FILE"
                    lsof -F pcfn -- "$_DB_PATH" 2>/dev/null | sed -n '1,80p' | tee -a "$_DANGER_LOG_FILE" || true
                fi
                if command_exists fuser; then
                    echo "[preflight] fuser holders for $_DB_PATH:" | tee -a "$_DANGER_LOG_FILE"
                    fuser -v -- "$_DB_PATH" 2>/dev/null | tee -a "$_DANGER_LOG_FILE" || true
                fi
            fi
        else
            echo "[preflight] No running chezmoi processes found via pgrep" | tee -a "$_DANGER_LOG_FILE"
        fi
    else
        echo "[preflight] pgrep not available; skipping process scan" | tee -a "$_DANGER_LOG_FILE"
    fi

    local lock_holders=""
    if [ -f "$db_path" ]; then
        if command_exists lsof; then
            lock_holders=$(lsof -F pcfn "$db_path" 2>/dev/null | sed -n '1,40p' || true)
        elif command_exists fuser; then
            lock_holders=$(fuser -v "$db_path" 2>/dev/null || true)
        fi
        if [ -n "$lock_holders" ]; then
            echo "[preflight] Persistent state DB appears to be open: $db_path" | tee -a "$_DANGER_LOG_FILE"
            echo "$lock_holders" | tee -a "$_DANGER_LOG_FILE"
        else
            echo "[preflight] No open handles detected on $db_path" | tee -a "$_DANGER_LOG_FILE"
        fi
    else
        echo "[preflight] State DB not present yet: $db_path" | tee -a "$_DANGER_LOG_FILE"
    fi

    # If either running chezmoi processes or open handles were detected, pause and offer interactive continue
    if [ -n "$procs" ] || [ -n "$lock_holders" ]; then
        local wait_secs msg
        wait_secs=${DEV_TEST_PREFLIGHT_WAIT_SECS:-20}
        msg="A running chezmoi instance or open state DB handle was detected. This can cause timeouts or transient failures.\n\n";
        msg+="Suggested actions:\n"
        msg+="  - Inspect/kill processes above if they are stale.\n"
        msg+="  - If stuck, rerun after killing stale chezmoi, or reboot the shell session.\n"
        msg+="  - Set DEV_TEST_SKIP_PREFLIGHT=1 to skip this check.\n\n"
        echo -e "$msg" | tee -a "$_DANGER_LOG_FILE"
        if is_interactive; then
          # Offer interactive pause only in interactive terminals
          pause_interactive "Review the above details. Press Enter to continue, or Ctrl+C to abort."
        else
          echo "[preflight] Non-interactive shell detected; continuing without pause." | tee -a "$_DANGER_LOG_FILE"
        fi
    fi
}

# Run preflight checks early
preflight_chezmoi_lock_check

# Preflight: ensure git working tree is clean and upstream is pushed

# Run all git checks; print details; return non-zero if any issue is found
_danger_git_check_all() {
  local issues=0

  # Untracked files
  local untracked
  untracked="$(git ls-files --others --exclude-standard 2>/dev/null || true)"
  if [ -n "$untracked" ]; then
    echo "[preflight][git] Untracked files detected:" | tee -a "$_DANGER_LOG_FILE"
    echo "$untracked" | sed -n '1,100p' | tee -a "$_DANGER_LOG_FILE"
    issues=1
  fi

  # Staged changes
  local staged
  staged="$(git diff --cached --name-status 2>/dev/null || true)"
  if [ -n "$staged" ]; then
    echo "[preflight][git] Staged but uncommitted changes detected:" | tee -a "$_DANGER_LOG_FILE"
    echo "$staged" | sed -n '1,100p' | tee -a "$_DANGER_LOG_FILE"
    issues=1
  fi

  # Unstaged modifications
  local modified
  modified="$(git diff --name-status 2>/dev/null || true)"
  if [ -n "$modified" ]; then
    echo "[preflight][git] Modified but unstaged changes detected:" | tee -a "$_DANGER_LOG_FILE"
    echo "$modified" | sed -n '1,100p' | tee -a "$_DANGER_LOG_FILE"
    issues=1
  fi

  # Unpushed commits
  local upstream ahead behind lr
  upstream="$(git rev-parse --abbrev-ref --symbolic-full-name @{u} 2>/dev/null || true)"
  if [ -n "$upstream" ]; then
    lr="$(git rev-list --left-right --count "$upstream"...HEAD 2>/dev/null || echo "0\t0")"
    behind="$(echo "$lr" | awk '{print $1}')"
    ahead="$(echo "$lr" | awk '{print $2}')"
    if [ "${ahead:-0}" -gt 0 ]; then
      echo "[preflight][git] Branch is ahead of upstream by $ahead commit(s); push pending: $(git rev-parse --abbrev-ref HEAD) -> $upstream" | tee -a "$_DANGER_LOG_FILE"
      issues=1
    fi
  else
    echo "[preflight][git] No upstream configured for $(git rev-parse --abbrev-ref HEAD); skipping unpushed check" | tee -a "$_DANGER_LOG_FILE"
  fi

  return $issues
}

preflight_git_clean_check() {
  local skip_git
  skip_git="${DANGER_SKIP_GIT_PREFLIGHT:-0}"
  [ "$skip_git" = "1" ] && { echo "[preflight] Skipping git cleanliness check (DANGER_SKIP_GIT_PREFLIGHT=1)" | tee -a "$_DANGER_LOG_FILE"; return 0; }

  # Only run if we're inside a git work tree
  if ! command_exists git || ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "[preflight] Not a git work tree; skipping git cleanliness check" | tee -a "$_DANGER_LOG_FILE"
    return 0
  fi

  echo "[preflight] Checking git work tree cleanliness and push state" | tee -a "$_DANGER_LOG_FILE"

  if !_danger_git_check_all; then
    : # unreachable; function returns numeric; but keep for clarity
  fi
  if [ $? -ne 0 ]; then
    echo "[preflight][git] Working tree is not clean or has unpushed commits. Please commit/stash/clean and push before running danger apply." | tee -a "$_DANGER_LOG_FILE"
    echo "[preflight][git] To override, set DANGER_SKIP_GIT_PREFLIGHT=1 (not recommended)." | tee -a "$_DANGER_LOG_FILE"
    # Print a short status for convenience
    echo "[preflight][git] git status --short --untracked-files=all:" | tee -a "$_DANGER_LOG_FILE"
    git status -s -uall 2>/dev/null | tee -a "$_DANGER_LOG_FILE" || true
    exit 3
  fi

  echo "[preflight] Git work tree is clean and up to date with upstream" | tee -a "$_DANGER_LOG_FILE"
}

preflight_git_clean_check

# Safety: refuse to run purge if ChezMoi source-path resolves to the current working tree.
assert_safe_purge() {
  local cwd src env_src
  cwd="$(pwd)"
  env_src="${CHEZMOI_SOURCE_DIR:-}"
  # Resolve chezmoi's configured source-path, if possible
  if command_exists chezmoi; then
    src="$(chezmoi source-path 2>/dev/null || true)"
  fi
  # If env var points at a git repo, and equals CWD, bail.
  if [ -n "$env_src" ] && [ -d "$env_src/.git" ] && [ "$env_src" = "$cwd" ]; then
    echo "[safety] Refusing to run 'chezmoi purge' because CHEZMOI_SOURCE_DIR points at current git working tree: $env_src" | tee -a "$_DANGER_LOG_FILE"
    exit 2
  fi
  # If chezmoi's source-path resolves to CWD, bail.
  if [ -n "$src" ] && [ "$src" = "$cwd" ]; then
    echo "[safety] Refusing to run 'chezmoi purge' because 'chezmoi source-path' resolves to this directory: $src" | tee -a "$_DANGER_LOG_FILE"
    exit 2
  fi
}

# Dry-run helpers for chezmoi steps
DRYRUN_TIMEOUT_SECS="${DANGER_DRYRUN_TIMEOUT_SECS:-90}"

# Try a command; if it fails due to unknown flag (e.g., --dry-run unsupported), return 2 to indicate fallback
_try_cmd_with_possible_unsupported_flag() {
  set +e
  eval "$1"
  local rc=$?
  set -e
  # Heuristic: if rc != 0, mark as fallback needed (2), else success (0)
  [ $rc -eq 0 ] && return 0 || return 2
}

dryrun_purge() {
  [ "${DANGER_SKIP_DRYRUN:-0}" = "1" ] && { echo "[dryrun] Skipping purge dry-run (DANGER_SKIP_DRYRUN=1)" | tee -a "$_DANGER_LOG_FILE"; return 0; }
  echo "[dryrun] Checking purge with dry-run or fallback diagnostics" | tee -a "$_DANGER_LOG_FILE"
  if _try_cmd_with_possible_unsupported_flag "timeout ${DRYRUN_TIMEOUT_SECS}s chezmoi purge --dry-run --debug 2>&1 | tee -a \"$_DANGER_LOG_FILE\""; then
    echo "[dryrun] Purge dry-run OK" | tee -a "$_DANGER_LOG_FILE"
    return 0
  fi
  # Fallback diagnostics when --dry-run isn't available: doctor + status in home context
  echo "[dryrun] Purge --dry-run not supported; running fallback diagnostics (doctor/status)" | tee -a "$_DANGER_LOG_FILE"
  timeout ${DRYRUN_TIMEOUT_SECS}s chezmoi doctor 2>&1 | tee -a "$_DANGER_LOG_FILE" || true
  timeout ${DRYRUN_TIMEOUT_SECS}s chezmoi status 2>&1 | tee -a "$_DANGER_LOG_FILE" || true
  echo "[dryrun] Fallback diagnostics completed" | tee -a "$_DANGER_LOG_FILE"
}

dryrun_init() {
  [ "${DANGER_SKIP_DRYRUN:-0}" = "1" ] && { echo "[dryrun] Skipping init dry-run (DANGER_SKIP_DRYRUN=1)" | tee -a "$_DANGER_LOG_FILE"; return 0; }
  echo "[dryrun] Checking init with dry-run or fallback status" | tee -a "$_DANGER_LOG_FILE"
  local src
  src="$(pwd)"
  if _try_cmd_with_possible_unsupported_flag "timeout ${DRYRUN_TIMEOUT_SECS}s chezmoi init --source \"$src\" --dry-run --debug 2>&1 | tee -a \"$_DANGER_LOG_FILE\""; then
    echo "[dryrun] Init dry-run OK" | tee -a "$_DANGER_LOG_FILE"
    return 0
  fi
  echo "[dryrun] Init --dry-run not supported; running fallback 'chezmoi --source \"$src\" status'" | tee -a "$_DANGER_LOG_FILE"
  timeout ${DRYRUN_TIMEOUT_SECS}s chezmoi --source "$src" status 2>&1 | tee -a "$_DANGER_LOG_FILE" || true
}

dryrun_apply() {
  [ "${DANGER_SKIP_DRYRUN:-0}" = "1" ] && { echo "[dryrun] Skipping apply dry-run (DANGER_SKIP_DRYRUN=1)" | tee -a "$_DANGER_LOG_FILE"; return 0; }
  echo "[dryrun] Running 'chezmoi apply --dry-run --verbose --debug'" | tee -a "$_DANGER_LOG_FILE"
  timeout ${DRYRUN_TIMEOUT_SECS}s env DEBUG_CHEZ_TPL=1 \
    chezmoi apply --dry-run --verbose --debug 2>&1 | tee -a "$_DANGER_LOG_FILE"
}

# Do the deed with dry-run gating before each step
assert_safe_purge
# Decouple purge from repo CWD for extra safety
cd "$HOME"
dryrun_purge
chezmoi purge --force --debug | tee -a "$_DANGER_LOG_FILE"
cd - >/dev/null 2>&1 || true
dryrun_init
chezmoi init --source "$(pwd)" --debug | tee -a "$_DANGER_LOG_FILE"
dryrun_apply

# Apply with:
#  - pager disabled by default via config (do not set CHEZMOI_ENABLE_PAGER)
#  - DEBUG_CHEZ_TPL=1 to get modify-template progress
#  - fast persistent-state timeout to avoid long lock waits
#  - outer timeout to prevent indefinite hangs
# Arrange an automatic SIGQUIT slightly before timeout to capture goroutines
APPLY_RC=0
AUTO_SIGQUIT_OFFSET=${DANGER_SIGQUIT_OFFSET_SECS:-15}
auto_sigquit() {
  local wait_secs
  wait_secs=$(( APPLY_TIMEOUT_SECS > AUTO_SIGQUIT_OFFSET ? APPLY_TIMEOUT_SECS - AUTO_SIGQUIT_OFFSET : APPLY_TIMEOUT_SECS/2 ))
  sleep "$wait_secs" || true
  local pid
  pid=$(pgrep -n chezmoi || true)
  if [ -n "$pid" ]; then
    echo "[danger] Sending SIGQUIT to chezmoi PID $pid (t+${wait_secs}s) to capture stacks" | tee -a "$_DANGER_LOG_FILE"
    kill -QUIT "$pid" 2>/dev/null || true
  fi
}
auto_sigquit &
AUTO_SIGQUIT_PID=$!
if command_exists strace; then
  echo "[danger] strace enabled; writing to $_DANGER_STRACE_FILE" | tee -a "$_DANGER_LOG_FILE"
  timeout "$APPLY_TIMEOUT_SECS"s env DEBUG_CHEZ_TPL=1 strace -f -tt -s 200 -o "$_DANGER_STRACE_FILE" \
    chezmoi apply --verbose --debug 2>&1 | tee -a "$_DANGER_LOG_FILE" ; APPLY_RC=${PIPESTATUS[0]}
else
  timeout "$APPLY_TIMEOUT_SECS"s env DEBUG_CHEZ_TPL=1 \
    chezmoi apply --verbose --debug 2>&1 | tee -a "$_DANGER_LOG_FILE" ; APPLY_RC=${PIPESTATUS[0]}
fi

# Stop auto-sigquit timer if still running
kill "$AUTO_SIGQUIT_PID" 2>/dev/null || true
wait "$AUTO_SIGQUIT_PID" 2>/dev/null || true

# Post-apply diagnostics
if [ "$APPLY_RC" -eq 124 ]; then
  echo "[danger] Apply timed out after ${APPLY_TIMEOUT_SECS}s (exit=124). Increase DANGER_APPLY_TIMEOUT_SECS or investigate long-running steps." | tee -a "$_DANGER_LOG_FILE"
elif [ "$APPLY_RC" -ne 0 ]; then
  echo "[danger] Apply exited with non-zero status: $APPLY_RC" | tee -a "$_DANGER_LOG_FILE"
else
  echo "[danger] Apply completed with exit code 0" | tee -a "$_DANGER_LOG_FILE"
fi

echo "[danger] Checking pending changes with 'chezmoi status --verbose'" | tee -a "$_DANGER_LOG_FILE"
chezmoi --source "$(pwd)" status --verbose 2>&1 | tee -a "$_DANGER_LOG_FILE" || true

echo "[danger] Done. Logs: $_DANGER_LOG_FILE | Strace: $_DANGER_STRACE_FILE" | tee -a "$_DANGER_LOG_FILE"
