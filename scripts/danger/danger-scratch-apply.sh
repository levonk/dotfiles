#!/usr/bin/env bash
set -euo pipefail

#
# Danger Chezmoi Apply Harness
#
# This script performs a safe, instrumented Chezmoi apply with strong preflights
# and guardrails. High-level flow:
#
# 1) Environment setup and CLI flags
#    - Adds ~/.local/bin to PATH.
#    - Supports --no-git-checks to skip repo cleanliness checks.
#
# 2) Preflights
#    - preflight_chezmoi_lock_check: report running chezmoi processes and
#      persistent-state DB locks; allows interactive pause.
#    - preflight_git_clean_check: require clean git tree and no unpushed commits
#      (skip with DANGER_SKIP_GIT_PREFLIGHT=1 or --no-git-checks).
#
# 3) Safety checks
#    - assert_safe_purge: refuses to run purge if chezmoi source-path or
#      CHEZMOI_SOURCE_DIR equals the current repo working tree.
#
# 4) Dry-run gates (hard stops on failure)
#    - dryrun_purge: try `chezmoi purge --dry-run`; on unsupported, run
#      doctor/status as a non-fatal fallback; on failure, re-run with full logging
#      then abort.
#    - dryrun_init: try `chezmoi init --source ... --dry-run`; on unsupported,
#      fall back to `chezmoi --source ... status`; on failure, re-run/log then abort.
#    - dryrun_apply: run `chezmoi apply --dry-run --verbose --debug`; on failure,
#      re-run with full logging then abort.
#    - Skip all dry-runs via DANGER_SKIP_DRYRUN=1.
#
# 5) Real operations (only after dry-runs pass)
#    - Run purge (from $HOME to decouple from repo CWD), then init (from repo),
#      then real apply with optional strace and an auto SIGQUIT timer to capture
#      goroutine stacks shortly before timeout.
#
# 6) Post-apply diagnostics
#    - Print exit status, then run `chezmoi --source "$(pwd)" status --verbose`.
#
# Tunables
#    - DANGER_APPLY_TIMEOUT_SECS: outer timeout for real apply (default 600s)
#    - DANGER_DRYRUN_TIMEOUT_SECS: timeout for each dry-run (default 90s)
#    - DANGER_SKIP_GIT_PREFLIGHT: skip git checks when set to 1
#    - DANGER_SKIP_DRYRUN: skip all dry-runs when set to 1
#    - DANGER_AUTO_CONTINUE_PREFLIGHT: if set to 1, auto-continue past chezmoi lock preflight without pausing
#    - DANGER_PREFLIGHT_DECISION: explicit non-interactive decision for chezmoi lock preflight: 'continue' or 'abort'
#
# Logs
#    - Main log:    $_DANGER_LOG_FILE
#    - Strace log:  $_DANGER_STRACE_FILE (when strace available)
#
# if ~/.local/bin is not in PATH, add it
case ":$PATH:" in
  *":$XDG_BIN_HOME:"*) : ;;  # already present
  *) export PATH="$XDG_BIN_HOME:$PATH" ;;
esac

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

# Required tool validation (fail fast with clear errors)
validate_required_tools() {
  local missing=0
  if ! command_exists git; then
    echo "[error] 'git' not found in PATH. Please install git and ensure it is available." | tee -a "$_DANGER_LOG_FILE"
    missing=1
  fi
  if ! command_exists chezmoi; then
    echo "[error] 'chezmoi' not found in PATH. Please install chezmoi and ensure it is available (expected in ~/.local/bin or system PATH)." | tee -a "$_DANGER_LOG_FILE"
    missing=1
  fi
  # Required: timeout (used for dry-runs and apply gating)
  if ! command_exists timeout; then
    echo "[error] 'timeout' not found in PATH. Please install coreutils (provides timeout) and ensure it is available." | tee -a "$_DANGER_LOG_FILE"
    missing=1
  fi
  # Optional tools: strace (for syscall tracing), lsof (for lock holders)
  if command_exists strace; then
    echo "[preflight] strace: $(strace -V 2>/dev/null | sed -n '1p')" | tee -a "$_DANGER_LOG_FILE"
  else
    echo "[preflight] strace not found; syscall tracing during apply will be skipped (optional)." | tee -a "$_DANGER_LOG_FILE"
  fi
  if command_exists lsof; then
    echo "[preflight] lsof: $(lsof -v 2>/dev/null | sed -n '1p')" | tee -a "$_DANGER_LOG_FILE"
  else
    echo "[preflight] lsof not found; lock holder inspection may be limited (optional)." | tee -a "$_DANGER_LOG_FILE"
  fi
  if command_exists fuser; then
    echo "[preflight] fuser: $(fuser -V 2>/dev/null | sed -n '1p')" | tee -a "$_DANGER_LOG_FILE"
  else
    echo "[preflight] fuser not found; lock holder inspection may be limited (optional)." | tee -a "$_DANGER_LOG_FILE"
  fi
  if [ "$missing" -ne 0 ]; then
    echo "[error] Required tools missing; aborting." | tee -a "$_DANGER_LOG_FILE"
    exit 127
  fi
  # Print short versions for traceability
  echo "[preflight] git: $(git --version 2>/dev/null | sed -n '1p')" | tee -a "$_DANGER_LOG_FILE"
  echo "[preflight] chezmoi: $(chezmoi --version 2>/dev/null | sed -n '1p')" | tee -a "$_DANGER_LOG_FILE"
  if command_exists timeout; then
    echo "[preflight] timeout: $(timeout --version 2>/dev/null | sed -n '1p')" | tee -a "$_DANGER_LOG_FILE"
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
        procs=$(pgrep -a -f '(^|/)chezmoi( |$)|(^|/)timeout( |$)' || true)
        if [ -n "$procs" ]; then
            echo "[preflight] Detected running chezmoi processes:" | tee -a "$_DANGER_LOG_FILE"
            echo "$procs" | tee -a "$_DANGER_LOG_FILE"
            # Provide copy-pasteable commands to resume/interrupt/terminate process groups
            echo "[preflight] Suggested recovery commands (copy-paste):" | tee -a "$_DANGER_LOG_FILE"
            while read -r line; do
              [ -z "$line" ] && continue
              # line like: "1234 chezmoi ..." -> extract PID
              pid=$(printf "%s\n" "$line" | awk '{print $1}')
              [ -z "$pid" ] && continue
              pgid=$(ps -o pgid= -p "$pid" 2>/dev/null | tr -d ' ')
              [ -z "$pgid" ] && pgid="$pid"
              echo "  # For PID $pid (PGID $pgid)" | tee -a "$_DANGER_LOG_FILE"
              echo "  kill -CONT $pid; kill -INT -$pgid  # resume then interrupt group" | tee -a "$_DANGER_LOG_FILE"
              echo "  kill -TERM -$pgid                  # graceful terminate group" | tee -a "$_DANGER_LOG_FILE"
              echo "  kill -KILL -$pgid                  # force kill group (last resort)" | tee -a "$_DANGER_LOG_FILE"
            done <<EOF
$(printf "%s\n" "$procs")
EOF
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

    # If either running chezmoi processes or open handles were detected, handle decision policy
    if [ -n "$procs" ] || [ -n "$lock_holders" ]; then
        local wait_secs msg decision
        wait_secs=${DEV_TEST_PREFLIGHT_WAIT_SECS:-20}
        msg="A running chezmoi instance or open state DB handle was detected. This can cause timeouts or transient failures.\n\n";
        msg+="Suggested actions:\n"
        msg+="  - Inspect/kill processes above if they are stale.\n"
        msg+="  - If stuck, rerun after killing stale chezmoi, or reboot the shell session.\n"
        msg+="  - Set DEV_TEST_SKIP_PREFLIGHT=1 to skip this check.\n\n"
        echo -e "$msg" | tee -a "$_DANGER_LOG_FILE"
        # Non-interactive overrides first
        decision="${DANGER_PREFLIGHT_DECISION:-}"
        if [ -z "$decision" ] && [ "${DANGER_AUTO_CONTINUE_PREFLIGHT:-0}" = "1" ]; then
          decision="continue"
        fi
        if [ -n "$decision" ]; then
          echo "[preflight] Using non-interactive preflight decision: $decision" | tee -a "$_DANGER_LOG_FILE"
          case "$decision" in
            continue|CONTINUE)
              : # proceed
              ;;
            abort|ABORT|stop|STOP)
              echo "[preflight] Aborting due to preflight decision ($decision)" | tee -a "$_DANGER_LOG_FILE"
              exit 4
              ;;
            *)
              echo "[preflight] Unknown DANGER_PREFLIGHT_DECISION='$decision'; defaulting to continue" | tee -a "$_DANGER_LOG_FILE"
              ;;
          esac
        else
          if is_interactive; then
            # Offer interactive pause only in interactive terminals
            echo "[preflight] Prompt: chezmoi activity detected. Press Enter to continue, or Ctrl+C to abort." | tee -a "$_DANGER_LOG_FILE" >&2
            pause_interactive "Review the above details. Press Enter to continue, or Ctrl+C to abort."
          else
            echo "[preflight] Non-interactive shell detected; continuing without pause." | tee -a "$_DANGER_LOG_FILE"
          fi
        fi
    fi
}

# Fail-fast guard: ensure Chezmoi's expected data dir exists AFTER init has run.
# Do NOT create it here; only explain what's missing and how to proceed.
preflight_data_dir_failfast() {
  # Resolve XDG_DATA_HOME default
  local xdg_data_home data_dir
  xdg_data_home="${XDG_DATA_HOME:-$HOME/.local/share}"
  data_dir="$xdg_data_home/chezmoi"

  # If chezmoi binary not present, skip (other checks will error)
  command_exists chezmoi || return 0

  if [ ! -d "$data_dir" ]; then
    echo "[preflight] Chezmoi data dir missing: $data_dir" | tee -a "$_DANGER_LOG_FILE"
    echo "[preflight] Fail-fast: 'chezmoi apply' will exit (stat $data_dir: no such file or directory)." | tee -a "$_DANGER_LOG_FILE"
    echo "[preflight] Note: 'chezmoi init --source "$(pwd)"' is expected to create necessary state. If it did not, inspect with:" | tee -a "$_DANGER_LOG_FILE"
    echo "  ~/.local/bin/chezmoi init --source \"$(pwd)\" --debug" | tee -a "$_DANGER_LOG_FILE"
    echo "  ~/.local/bin/chezmoi doctor" | tee -a "$_DANGER_LOG_FILE"
    echo "[preflight] To rerun danger after addressing, execute: scripts/danger/danger-scratch-apply.sh" | tee -a "$_DANGER_LOG_FILE"
    exit 20
  fi
}

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

  # Note: space after '!' is required in bash/zsh
  if ! _danger_git_check_all; then
    echo "[preflight][git] Working tree is not clean or has unpushed commits. Please commit/stash/clean and push before running danger apply." | tee -a "$_DANGER_LOG_FILE"
    echo "[preflight][git] To override, set DANGER_SKIP_GIT_PREFLIGHT=1 (not recommended)." | tee -a "$_DANGER_LOG_FILE"
    # Print a short status for convenience
    echo "[preflight][git] git status --short --untracked-files=all:" | tee -a "$_DANGER_LOG_FILE"
    git status -s -uall 2>/dev/null | tee -a "$_DANGER_LOG_FILE" || true
    exit 3
  fi

  echo "[preflight] Git work tree is clean and up to date with upstream" | tee -a "$_DANGER_LOG_FILE"
}

# Run preflight checks early
validate_required_tools
preflight_git_clean_check

# Validate that all Chezmoi templates are parsable
echo "[preflight] Validating all Chezmoi templates..."
if ! ./scripts/tests/test-chezmoi-templates.sh; then
  echo "[error] Chezmoi template validation failed. Aborting." | tee -a "$_DANGER_LOG_FILE"
  exit 15
fi
echo "[preflight] All Chezmoi templates are valid."

preflight_chezmoi_lock_check


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
DRYRUN_TIMEOUT_SECS="${DANGER_DRYRUN_TIMEOUT_SECS:-600}"

# Try a command; distinguish between "unsupported flag" and real failure.
# Returns: 0 on success; 2 if flag unsupported; 1 on real failure.
_try_cmd_with_possible_unsupported_flag() {
  local cmd="$1"
  local out rc
  set +e
  out=$(eval "$cmd" 2>&1)
  rc=$?
  set -e
  printf "%s\n" "$out" | tee -a "$_DANGER_LOG_FILE" >/dev/null
  if [ $rc -eq 0 ]; then
    return 0
  fi
  if printf "%s" "$out" | grep -qiE "unknown (flag|option)|flag provided but not defined|unrecognized option"; then
    return 2
  fi
  return 1
}

dryrun_purge() {
  [ "${DANGER_SKIP_DRYRUN:-0}" = "1" ] && { echo "[dryrun] Skipping purge dry-run (DANGER_SKIP_DRYRUN=1)" | tee -a "$_DANGER_LOG_FILE"; return 0; }
  echo "[dryrun] Checking purge with dry-run or fallback diagnostics" | tee -a "$_DANGER_LOG_FILE"
  _try_cmd_with_possible_unsupported_flag "timeout ${DRYRUN_TIMEOUT_SECS}s chezmoi purge --dry-run --force --debug"
  case $? in
    0)
      echo "[dryrun] Purge dry-run OK" | tee -a "$_DANGER_LOG_FILE"; return 0 ;;
    2)
      echo "[dryrun] Purge --dry-run not supported; running fallback diagnostics (doctor/status)" | tee -a "$_DANGER_LOG_FILE"
      timeout ${DRYRUN_TIMEOUT_SECS}s chezmoi doctor || true | tee -a "$_DANGER_LOG_FILE"
      timeout ${DRYRUN_TIMEOUT_SECS}s chezmoi status || true | tee -a "$_DANGER_LOG_FILE"
      echo "[dryrun] Fallback diagnostics completed (non-fatal)" | tee -a "$_DANGER_LOG_FILE"
      return 0 ;;
    *)
      echo "[dryrun] Purge dry-run failed; re-running to capture full output then aborting" | tee -a "$_DANGER_LOG_FILE"
      timeout ${DRYRUN_TIMEOUT_SECS}s chezmoi purge --force --dry-run --debug 2>&1 | tee -a "$_DANGER_LOG_FILE" || true
      echo "[dryrun] Purge dry-run failed; aborting to avoid destructive action" | tee -a "$_DANGER_LOG_FILE"
      return 1 ;;
  esac
}

dryrun_init() {
  [ "${DANGER_SKIP_DRYRUN:-0}" = "1" ] && { echo "[dryrun] Skipping init dry-run (DANGER_SKIP_DRYRUN=1)" | tee -a "$_DANGER_LOG_FILE"; return 0; }
  echo "[dryrun] Checking init with dry-run or fallback status" | tee -a "$_DANGER_LOG_FILE"
  local src
  src="$(pwd)"
  _try_cmd_with_possible_unsupported_flag "timeout ${DRYRUN_TIMEOUT_SECS}s chezmoi init --source \"$src\" --dry-run --debug"
  case $? in
    0)
      echo "[dryrun] Init dry-run OK" | tee -a "$_DANGER_LOG_FILE"; return 0 ;;
    2)
      echo "[dryrun] Init --dry-run not supported; running fallback 'chezmoi --source \"$src\" status'" | tee -a "$_DANGER_LOG_FILE"
      timeout ${DRYRUN_TIMEOUT_SECS}s chezmoi --source "$src" status || true | tee -a "$_DANGER_LOG_FILE"
      return 0 ;;
    *)
      echo "[dryrun] Init dry-run failed; re-running to capture full output then aborting" | tee -a "$_DANGER_LOG_FILE"
      timeout ${DRYRUN_TIMEOUT_SECS}s chezmoi init --source "$src" --dry-run --debug 2>&1 | tee -a "$_DANGER_LOG_FILE" || true
      echo "[dryrun] Init dry-run failed; aborting" | tee -a "$_DANGER_LOG_FILE"; return 1 ;;
  esac
}

dryrun_apply() {
  [ "${DANGER_SKIP_DRYRUN:-0}" = "1" ] && { echo "[dryrun] Skipping apply dry-run (DANGER_SKIP_DRYRUN=1)" | tee -a "$_DANGER_LOG_FILE"; return 0; }
  echo "[dryrun] Running 'chezmoi apply --dry-run --verbose --debug'" | tee -a "$_DANGER_LOG_FILE"
  timeout ${DRYRUN_TIMEOUT_SECS}s env DEBUG_CHEZ_TPL=1 \
    chezmoi apply --dry-run --verbose --debug
  local rc=$?
  if [ $rc -ne 0 ]; then
    echo "[dryrun] Apply dry-run failed (exit=$rc); re-running to capture full output then aborting" | tee -a "$_DANGER_LOG_FILE"
    timeout ${DRYRUN_TIMEOUT_SECS}s env DEBUG_CHEZ_TPL=1 \
      chezmoi apply --dry-run --verbose --debug 2>&1 | tee -a "$_DANGER_LOG_FILE" || true
    echo "[dryrun] Apply dry-run failed (exit=$rc); aborting" | tee -a "$_DANGER_LOG_FILE"
    return 1
  fi
}

# Do the deed with dry-run gating before each step

echo "[setup] Clearing dotfiles cache at ~/.cache/dotfiles" | tee -a "$_DANGER_LOG_FILE"
rm -rf "$HOME/.cache/dotfiles"

assert_safe_purge
# Decouple purge from repo CWD for extra safety
cd "$HOME"
if ! dryrun_purge; then exit 10; fi
# Add timeout to real purge to avoid potential hangs
timeout "${DANGER_APPLY_TIMEOUT_SECS:-600}"s chezmoi purge --force --debug 2>&1 | tee -a "$_DANGER_LOG_FILE" || true
cd - >/dev/null 2>&1 || true
if ! dryrun_init; then exit 11; fi
# Add timeout to real init to avoid potential hangs, interactive prompts causing hangs
#timeout "${DANGER_APPLY_TIMEOUT_SECS:-600}"s chezmoi init --source "$(pwd)" --debug 2>&1 | tee -a "$_DANGER_LOG_FILE" || true
chezmoi init --source "$(pwd)" --debug 2>&1 | tee -a "$_DANGER_LOG_FILE"
# Re-create the data dir if it was purged during dry-run, then fail-fast if it's still missing
mkdir -p "${XDG_DATA_HOME:-$HOME/.local/share}/chezmoi"
preflight_data_dir_failfast
if ! dryrun_apply; then exit 12; fi

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
