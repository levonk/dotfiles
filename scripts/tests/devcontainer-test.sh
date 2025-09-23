#!/usr/bin/env bash
# =====================================================================
# DevContainer Automated Testing Script
# Managed by chezmoi | https://github.com/levonk/dotfiles
#
# Purpose:
#   - Automatically run comprehensive dotfiles tests in devcontainer
#   - Performance benchmarking and validation
#   - Cross-shell compatibility testing
# =====================================================================

set -euo pipefail

# Variables for DRY principle
# Detect if we're running in the devcontainer or locally
if [ -d "/workspace" ]; then
    # Running inside devcontainer
    WORKSPACE_DIR="/workspace"
else
    # Running locally - determine repo root from scripts/tests path
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    # SCRIPT_DIR => /path/to/repo/scripts/tests ; go up two levels to reach repo root
    WORKSPACE_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"
fi

TESTS_DIR="$WORKSPACE_DIR/scripts/tests"
BATS_TEST_FILE="$TESTS_DIR/shell-tests.bats"
LOG_FILE="/tmp/dotfiles-test-$(date +%Y%m%d-%H%M%S).log"
# Default per-test timeout (seconds). Can override via DEV_TEST_TIMEOUT_SECS env var
DEV_TEST_TIMEOUT_SECS="${DEV_TEST_TIMEOUT_SECS:-60}"
DEV_TEST_REAL_APPLY="${DEV_TEST_REAL_APPLY:-0}"
# Fail fast if another chezmoi instance holds the persistent-state lock
CHEZMOI_LOCK_TIMEOUT="${CHEZMOI_LOCK_TIMEOUT:-3s}"
TEST_FAILURES=0
TIMEOUTS_DETECTED=0

echo "🧪 Starting automated dotfiles testing..." | tee "$LOG_FILE"
echo "📅 Test run: $(date)" | tee -a "$LOG_FILE"
echo "🖥️  Container: $(hostname)" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"

# Ensure common install locations are on PATH for both host and container
export PATH="$HOME/.local/bin:/usr/local/bin:$PATH"

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Determine if running in an interactive terminal
is_interactive() {
    [ -t 0 ] || [ -t 1 ] || [ -t 2 ] || [ -r /dev/tty ]
}

# Interactive pause helper: prefers /dev/tty to avoid issues when stdout is piped
pause_interactive() {
    local note="${1:-Press Enter to continue, or Ctrl+C to abort}"; local ans=""
    local pause_secs="${DEV_TEST_PAUSE_SECS:-5}"
    if is_interactive; then
        # Timed prompt; auto-continue after pause_secs to avoid indefinite hangs
        if [ -r /dev/tty ]; then
            if ! read -t "$pause_secs" -r -p "[preflight] $note (auto-continue in ${pause_secs}s) > " ans </dev/tty; then
                echo "[preflight] No input after ${pause_secs}s; continuing." | tee -a "$LOG_FILE" >&2
            fi
        else
            if ! read -t "$pause_secs" -r -p "[preflight] $note (auto-continue in ${pause_secs}s) > " ans; then
                echo "[preflight] No input after ${pause_secs}s; continuing." | tee -a "$LOG_FILE" >&2
            fi
        fi
    fi
}

# Preflight: detect existing chezmoi processes and potential state DB locks
preflight_chezmoi_lock_check() {
    local skip_preflight
    skip_preflight="${DEV_TEST_SKIP_PREFLIGHT:-0}"
    [ "$skip_preflight" = "1" ] && { echo "[preflight] Skipping chezmoi lock check (DEV_TEST_SKIP_PREFLIGHT=1)" | tee -a "$LOG_FILE"; return 0; }

    local db_path
    db_path="$HOME/.config/chezmoi/chezmoistate.boltdb"

    echo "[preflight] Checking for running chezmoi processes and locks" | tee -a "$LOG_FILE"

    local procs=""
    if command_exists pgrep; then
        procs=$(pgrep -a chezmoi || true)
        if [ -n "$procs" ]; then
            echo "[preflight] Detected running chezmoi processes:" | tee -a "$LOG_FILE"
            echo "$procs" | tee -a "$LOG_FILE"
        else
            echo "[preflight] No running chezmoi processes found via pgrep" | tee -a "$LOG_FILE"
        fi
    else
        echo "[preflight] pgrep not available; skipping process scan" | tee -a "$LOG_FILE"
    fi

    local lock_holders=""
    if [ -f "$db_path" ]; then
        if command_exists lsof; then
            lock_holders=$(lsof -F pcfn "$db_path" 2>/dev/null | sed -n '1,40p' || true)
        elif command_exists fuser; then
            lock_holders=$(fuser -v "$db_path" 2>/dev/null || true)
        fi
        if [ -n "$lock_holders" ]; then
            echo "[preflight] Persistent state DB appears to be open: $db_path" | tee -a "$LOG_FILE"
            echo "$lock_holders" | tee -a "$LOG_FILE"
        else
            echo "[preflight] No open handles detected on $db_path" | tee -a "$LOG_FILE"
        fi
    else
        echo "[preflight] State DB not present yet: $db_path" | tee -a "$LOG_FILE"
    fi

    # If either running processes or open handles were detected, offer an interactive pause
    if [ -n "$procs" ] || [ -n "$lock_holders" ]; then
        local msg
        msg="A running chezmoi instance or open state DB handle was detected. This can cause timeouts or transient failures.\n\n";
        msg+="Suggested actions:\n"
        msg+="  - Inspect/kill processes above if they are stale.\n"
        msg+="  - Re-run once existing runs are finished.\n"
        msg+="  - Set DEV_TEST_SKIP_PREFLIGHT=1 to skip this check.\n\n"
        echo -e "$msg" | tee -a "$LOG_FILE"
        if is_interactive; then
            pause_interactive "Review the above details. Press Enter to continue, or Ctrl+C to abort."
        else
            echo "[preflight] Non-interactive shell detected; continuing without pause." | tee -a "$LOG_FILE"
        fi
    fi
}

# Run preflight checks early
preflight_chezmoi_lock_check

# Create a temporary HOME layer inside the container so real apply doesn't mutate the actual user home.
# Returns the path in TEMPHOME and exports XDG dirs pointing into it. Caller must cleanup.
create_temp_home_layer() {
    TEMPHOME=$(mktemp -d /tmp/chez-home.XXXXXX)
    mkdir -p "$TEMPHOME/.config" "$TEMPHOME/.local/share" "$TEMPHOME/.local/state" "$TEMPHOME/.cache" "$TEMPHOME/.local/bin"
    export XDG_CONFIG_HOME="$TEMPHOME/.config"
    export XDG_DATA_HOME="$TEMPHOME/.local/share"
    export XDG_STATE_HOME="$TEMPHOME/.local/state"
    export XDG_CACHE_HOME="$TEMPHOME/.cache"
    export PATH="$TEMPHOME/.local/bin:$PATH"
}

cleanup_temp_home_layer() {
    if [ -n "${TEMPHOME:-}" ] && [ -d "$TEMPHOME" ]; then
        rm -rf "$TEMPHOME" || true
    fi
}

# -----------------------------
# Multiuser test helpers
# -----------------------------

have_root() { [ "$(id -u)" -eq 0 ]; }
have_sudo() { command -v sudo >/dev/null 2>&1; }

user_home_dir() {
  getent passwd "$1" 2>/dev/null | awk -F: '{print $6}'
}

ensure_user() {
  # $1=username, $2=shell
  local u="$1" s="$2"
  if id -u "$u" >/dev/null 2>&1; then
    echo "[multiuser] User exists: $u" | tee -a "$LOG_FILE"
    return 0
  fi
  if have_root; then
    useradd -m -s "$s" "$u" && echo "[multiuser] Created user: $u ($s)" | tee -a "$LOG_FILE"
  elif have_sudo; then
    sudo useradd -m -s "$s" "$u" && echo "[multiuser] Created user with sudo: $u ($s)" | tee -a "$LOG_FILE"
  else
    echo "[multiuser] Cannot create user $u: need root or sudo" | tee -a "$LOG_FILE"
    return 1
  fi
}

remove_user() {
  # $1=username
  local u="$1"
  if ! id -u "$u" >/dev/null 2>&1; then return 0; fi
  if have_root; then
    userdel -r "$u" 2>/dev/null || true
  elif have_sudo; then
    sudo userdel -r "$u" 2>/dev/null || true
  fi
}

copy_wrappers_into_user_home() {
  # $1=username
  local u="$1" home
  home="$(user_home_dir "$u")"
  [ -n "$home" ] || { echo "[multiuser] No home for $u" | tee -a "$LOG_FILE"; return 1; }
  local src_dir="$WORKSPACE_DIR/home/current/dot_local/bin"
  local dst_dir="$home/.local/bin"
  mkdir -p "$dst_dir"
  install -m 0755 "$src_dir/executable_grep"  "$dst_dir/grep"  || true
  install -m 0755 "$src_dir/executable_egrep" "$dst_dir/egrep" || true
  install -m 0755 "$src_dir/executable_fgrep" "$dst_dir/fgrep" || true
  if have_root; then
    chown -R "$u":"$u" "$home/.local" 2>/dev/null || true
  elif have_sudo; then
    sudo chown -R "$u":"$u" "$home/.local" 2>/dev/null || true
  fi
}

run_as_user() {
  # $1=username, $2=command string
  local u="$1" cmd="$2"
  if have_root; then
    su - "$u" -c "$cmd"
  elif have_sudo; then
    sudo -H -u "$u" bash -lc "$cmd"
  else
    echo "[multiuser] Cannot run as $u: need root or sudo" | tee -a "$LOG_FILE"
    return 1
  fi
}

run_chezmoi_as_user() {
  # $1=username, $2=shell (/bin/bash or /bin/zsh)
  local u="$1" shell_path="$2" home envs cmd rc
  home="$(user_home_dir "$u")"
  [ -n "$home" ] || { echo "[multiuser] No home for $u" | tee -a "$LOG_FILE"; return 1; }

  # Prepare environment and sanity probe for wrappers
  envs="HOME=$home XDG_CONFIG_HOME=$home/.config XDG_DATA_HOME=$home/.local/share XDG_STATE_HOME=$home/.local/state XDG_CACHE_HOME=$home/.cache PATH=$home/.local/bin:/usr/local/bin:/usr/bin:/bin"

  echo "[multiuser] ($u) Wrapper sanity probe" | tee -a "$LOG_FILE"
  run_test_suite "Wrapper Sanity ($u)" \
    "env $envs timeout ${DEV_TEST_TIMEOUT_SECS}s bash -lc 'printf x | grep -Fqx x'"

  # Chezmoi apply in user's home; disable package installs and shell switching
  cmd="env CHEZMOI_INSTALL_PKGS=0 CHEZMOI_NO_SHELL_SWITCH=1 CHEZMOI_PKGS_DRY_RUN=1 $envs \"chezmoi --source=\"$WORKSPACE_DIR/home/current\" --destination=\"$home\" apply --verbose --debug\""
    echo "[multiuser] ($u) chezmoi apply via $shell_path" | tee -a "$LOG_FILE"
    run_test_suite "ChezMoi Apply ($u,$(basename "$shell_path"))" \
      "$shell_path -lc $cmd"
}

multiuser_test_flow() {
  local enabled="${DEV_TEST_MULTIUSER:-1}"
  if [ "$enabled" != "1" ]; then
    echo "[multiuser] Skipping multiuser test (DEV_TEST_MULTIUSER=$enabled)" | tee -a "$LOG_FILE"
    return 0
  fi

  if ! have_root && ! have_sudo; then
    echo "[multiuser] Skipping: neither root nor sudo is available" | tee -a "$LOG_FILE"
    return 0
  fi

  echo "" | tee -a "$LOG_FILE"
  echo "👥 Running multiuser wrapper/apply tests" | tee -a "$LOG_FILE"

  local u1="dotftest1" u2="dotftest2" rc=0
  ensure_user "$u1" "/bin/zsh" || rc=1
  ensure_user "$u2" "/bin/bash" || rc=1
  [ $rc -ne 0 ] && { echo "[multiuser] Failed to create test users" | tee -a "$LOG_FILE"; return 0; }

  # Install wrappers via chezmoi into each user's HOME to mirror real install
  install_wrappers_via_chezmoi_as_user "$u1" "/bin/zsh"
  install_wrappers_via_chezmoi_as_user "$u2" "/bin/bash"

  # Run as zsh user then bash user
  run_chezmoi_as_user "$u1" "/bin/zsh"
  run_chezmoi_as_user "$u2" "/bin/bash"

  # Cleanup users (best-effort)
  remove_user "$u1"
  remove_user "$u2"
}

# Verify that key files from the chezmoi source are materialized into a target HOME after a real apply.
# Writes [OK]/[FAIL] markers to the test log so the summary scanner can detect issues.
verify_materialization() {
    local target_home="$1"
    echo "🔎 Verifying materialization into $target_home" | tee -a "$LOG_FILE"

    local -a expected_files=(
        ".zshenv"
        ".editorconfig"
        ".config/shells/shared/entrypointrc.sh"
    )
    local -a expected_exec=(
        ".xprofile"
        ".xinitrc"
    )

    local missing=0
    for rel in "${expected_files[@]}"; do
        if [ -f "$target_home/$rel" ]; then
            echo "[OK] Materialization: present $rel" | tee -a "$LOG_FILE"
        else
            echo "[FAIL] Materialization: missing $rel" | tee -a "$LOG_FILE"
            missing=$((missing+1))
        fi
    done
    for rel in "${expected_exec[@]}"; do
        if [ -x "$target_home/$rel" ]; then
            echo "[OK] Materialization: executable $rel" | tee -a "$LOG_FILE"
        else
            # Distinguish missing from non-executable for better diagnostics
            if [ -e "$target_home/$rel" ]; then
                echo "[FAIL] Materialization: not executable $rel" | tee -a "$LOG_FILE"
            else
                echo "[FAIL] Materialization: missing $rel" | tee -a "$LOG_FILE"
            fi
            missing=$((missing+1))
        fi
    done

    # Light diagnostics to help debugging when failures occur
    if [ "$missing" -gt 0 ]; then
        {
          echo "[diag] Listing top-level of $target_home"
          ls -la "$target_home" || true
          echo "[diag] Listing ~/.config (2 levels)"
          find "$target_home/.config" -maxdepth 2 -type f -print 2>/dev/null | sed -n '1,200p' || true
        } >> "$LOG_FILE" 2>&1
    fi
}

# Function to run tests with timing and timeout
run_test_suite() {
    local test_name="$1"
    local test_command="$2"
    local start_time end_time duration rc
    echo "🔍 Running $test_name..." | tee -a "$LOG_FILE"
    start_time=$(date +%s.%N)
    if command -v timeout >/dev/null 2>&1; then
        # Use KILL to be decisive if a child stalls
        set +e
        timeout --signal=KILL ${DEV_TEST_TIMEOUT_SECS}s bash -lc "$test_command" >> "$LOG_FILE" 2>&1
        rc=$?
        set -e
        if [ $rc -eq 137 ] || [ $rc -eq 124 ]; then
            end_time=$(date +%s.%N)
            duration=$(echo "$end_time - $start_time" | bc -l 2>/dev/null || echo "N/A")
            echo "⏳ $test_name timed out after ${DEV_TEST_TIMEOUT_SECS}s (${duration}s)" | tee -a "$LOG_FILE"
            echo "[TIMEOUT] $test_name after ${DEV_TEST_TIMEOUT_SECS}s" | tee -a "$LOG_FILE"
            TIMEOUTS_DETECTED=1
            TEST_FAILURES=1
            return 0
        fi
    else
        # No timeout available; run directly
        set +e
        eval "$test_command" >> "$LOG_FILE" 2>&1
        rc=$?
        set -e
    fi
    end_time=$(date +%s.%N)
    duration=$(echo "$end_time - $start_time" | bc -l 2>/dev/null || echo "N/A")
    if [ $rc -eq 0 ]; then
        echo "✅ $test_name completed successfully (${duration}s)" | tee -a "$LOG_FILE"
        echo "[OK] $test_name" | tee -a "$LOG_FILE"
        return 0
    else
        echo "❌ $test_name failed (rc=$rc, ${duration}s)" | tee -a "$LOG_FILE"
        echo "[FAIL] $test_name rc=$rc" | tee -a "$LOG_FILE"
        TEST_FAILURES=1
        return 0
    fi
}

# Test environment validation
echo "🔧 Validating test environment..." | tee -a "$LOG_FILE"

# Check if we're in the workspace
if [ ! -d "$WORKSPACE_DIR" ]; then
    echo "❌ Workspace directory not found: $WORKSPACE_DIR" | tee -a "$LOG_FILE"
    exit 1
fi

# Check if tests directory exists
if [ ! -d "$TESTS_DIR" ]; then
    echo "❌ Tests directory not found: $TESTS_DIR" | tee -a "$LOG_FILE"
    exit 1
fi

# Check if bats test file exists
if [ ! -f "$BATS_TEST_FILE" ]; then
    echo "❌ Bats test file not found: $BATS_TEST_FILE" | tee -a "$LOG_FILE"
    exit 1
fi

echo "✅ Test environment validated" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"

# Run comprehensive test suite
echo "🚀 Executing test suite..." | tee -a "$LOG_FILE"

# Test 1: Bats shell configuration tests
# Some environments have a broken shim (e.g., ~/.local/bin/bats -> bunx) which fails at runtime.
# Verify bats is functional by checking its version first.
if command -v bats >/dev/null 2>&1; then
    if bats --version >/dev/null 2>&1; then
        run_test_suite "Shell Configuration Tests" "cd '$WORKSPACE_DIR' && BATS_TEST_DIRNAME='$TESTS_DIR' bats '$BATS_TEST_FILE'"
    else
        echo "⚠️  Bats found but not functional (likely a broken shim in ~/.local/bin/bats). Skipping shell tests." | tee -a "$LOG_FILE"
        echo "   Fix suggestion: remove the broken shim or install bats-core (e.g., apt-get install bats, or npm -g install bats)." | tee -a "$LOG_FILE"
    fi
else
    echo "⚠️  Bats testing framework not found. Skipping shell tests." | tee -a "$LOG_FILE"
    echo "   To install bats: npm install -g bats or apt-get install bats" | tee -a "$LOG_FILE"
fi

# Test 2: Shell startup performance (bash)
if command_exists bash && [ -f "$HOME/.bashrc" ]; then
    run_test_suite "Bash Startup Performance" "time bash -c 'source ~/.bashrc && exit'"
else
    echo "⚠️  Bash configuration not found or bash not available. Skipping bash startup test." | tee -a "$LOG_FILE"
fi

# Test 3: Shell startup performance (zsh)
if command_exists zsh && [ -f "$HOME/.zshrc" ]; then
    run_test_suite "Zsh Startup Performance" "time zsh -c 'source ~/.zshrc && exit'"
else
    echo "⚠️  Zsh configuration not found or zsh not available. Skipping zsh startup test." | tee -a "$LOG_FILE"
fi

# Test 4: Git configuration validation
if command_exists git; then
    echo "✅ Git is available, checking configuration..." | tee -a "$LOG_FILE"
    # Avoid reading includes or repo-specific configs which might hang; only inspect global config.
    run_test_suite "Git Configuration Validation" "GIT_TERMINAL_PROMPT=0 GIT_ASKPASS=/bin/false GIT_PAGER=cat git --version && (GIT_CONFIG_NOSYSTEM=1 GIT_TERMINAL_PROMPT=0 GIT_ASKPASS=/bin/false GIT_PAGER=cat git config --global --list --show-origin --no-includes 2>/dev/null | grep -E '^(user\\.|core\\.)' || echo 'No git global config found')"
else
    echo "⚠️  Git not available, skipping validation" | tee -a "$LOG_FILE"
fi

# Test 5: Local bin scripts validation
if [ -d "$HOME/.local/bin" ] && [ "$(ls -A $HOME/.local/bin)" ]; then
    run_test_suite "Local Scripts Validation" "ls -la '$HOME/.local/bin' && file '$HOME/.local/bin/'*"
else
    echo "⚠️  No local bin scripts found, skipping validation" | tee -a "$LOG_FILE"
fi

# Test 6: Platform detection
if [ -f "$HOME/.config/shells/shared/util/platform-detection.sh" ]; then
    run_test_suite "Platform Detection" "source '$HOME/.config/shells/shared/util/platform-detection.sh' && echo 'Platform detection loaded successfully'"
else
    echo "⚠️  Platform detection utility not found, skipping test" | tee -a "$LOG_FILE"
fi

# Test 7: Performance utilities
if [ -f "$HOME/.config/shells/shared/util/file-cache.sh" ]; then
    run_test_suite "Performance Utilities" "source '$HOME/.config/shells/shared/util/file-cache.sh' && echo 'Cache utilities loaded'"
else
    echo "⚠️  Performance utilities not found, skipping test" | tee -a "$LOG_FILE"
fi

# Test 8: ChezMoi checks (version, source-path, doctor, apply)
if command_exists chezmoi; then
    # Hermetic dry-run: use repo source and a temporary destination HOME
    DRY_SRC="$WORKSPACE_DIR/home/current"
    DRY_DEST="$(mktemp -d /tmp/chez-dry-home.XXXXXX)"
    mkdir -p "$DRY_DEST/.config" "$DRY_DEST/.local/share" "$DRY_DEST/.local/state" "$DRY_DEST/.cache"
    DRY_ENV="HOME=$DRY_DEST XDG_CONFIG_HOME=$DRY_DEST/.config XDG_DATA_HOME=$DRY_DEST/.local/share XDG_STATE_HOME=$DRY_DEST/.local/state XDG_CACHE_HOME=$DRY_DEST/.cache"

    # Version and doctor
    run_test_suite "ChezMoi Version & Doctor" "$DRY_ENV chezmoi --source=\"$DRY_SRC\" --destination=\"$DRY_DEST\" --version && echo '---' && $DRY_ENV chezmoi --source=\"$DRY_SRC\" --destination=\"$DRY_DEST\" doctor"
    # Source-path should exist; validate existence under our repo checkout
    run_test_suite "ChezMoi Source Path" "SRC=\$($DRY_ENV chezmoi --source=\"$DRY_SRC\" --destination=\"$DRY_DEST\" source-path); echo SourcePath=\"\$SRC\"; test -d \"\$SRC\""
    # Apply (dry-run to avoid unintended mutations; traced if available)
    CHEZ_APPLY_CMD="chezmoi --source=\"$DRY_SRC\" --destination=\"$DRY_DEST\" apply --dry-run --verbose --debug"
    if command_exists strace; then
        echo "ℹ️  strace detected; tracing chezmoi apply to /tmp/chezmoi-apply.strace.log" | tee -a "$LOG_FILE"
        run_test_suite "ChezMoi Apply (dry-run, traced)" "env $DRY_ENV strace -f -tt -s 200 -o /tmp/chezmoi-apply.strace.log $CHEZ_APPLY_CMD"
    else
        run_test_suite "ChezMoi Apply (dry-run)" "env $DRY_ENV $CHEZ_APPLY_CMD"
    fi
    # Additional dry-run with pager explicitly enabled to surface potential pager hangs.
    # Pager is disabled by default in config; opt-in here to test behavior.
    run_test_suite "ChezMoi Apply (dry-run, pager ON)" "env CHEZMOI_ENABLE_PAGER=1 $DRY_ENV $CHEZ_APPLY_CMD"
    # Post-apply status snapshot to see pending items (against our hermetic dest)
    run_test_suite "ChezMoi Status (after dry-run applies)" "env $DRY_ENV chezmoi --source=\"$DRY_SRC\" --destination=\"$DRY_DEST\" status --verbose"

    # Diagnostics and cleanup for dry-run dest
    {
      echo "[diag] Dry-run DEST: $DRY_DEST"; ls -la "$DRY_DEST" || true
      echo "[diag] Dry-run DEST .config (2 levels):"; find "$DRY_DEST/.config" -maxdepth 2 -type d -print | sed -n '1,50p' || true
    } >> "$LOG_FILE" 2>&1
    rm -rf "$DRY_DEST" || true
else
    echo "⚠️  chezmoi not available, skipping chezmoi tests." | tee -a "$LOG_FILE"
fi

# Optional: Real chezmoi apply using a temporary HOME layer inside the container
if [ "$DEV_TEST_REAL_APPLY" = "1" ] && command_exists chezmoi; then
    echo "" | tee -a "$LOG_FILE"
    echo "🧪 Running real chezmoi apply in a temporary HOME layer (container-only)" | tee -a "$LOG_FILE"
    create_temp_home_layer
    trap cleanup_temp_home_layer EXIT
    # Disable interactive operations; ensure we don't switch shells or install packages
    # Still a real apply; writes into TEMPHOME only. Pager is OFF by default via config.
    REAL_ENV="HOME=$TEMPHOME XDG_CONFIG_HOME=$XDG_CONFIG_HOME XDG_DATA_HOME=$XDG_DATA_HOME XDG_STATE_HOME=$XDG_STATE_HOME XDG_CACHE_HOME=$XDG_CACHE_HOME CHEZMOI_INSTALL_PKGS=0 CHEZMOI_NO_SHELL_SWITCH=1 CHEZMOI_INSTALL_ZSH=0 CHEZMOI_PKGS_DRY_RUN=1"
    REAL_SRC="$WORKSPACE_DIR/home/current"
    REAL_DEST="$TEMPHOME"
    REAL_CMD="$REAL_ENV chezmoi --source=\"$REAL_SRC\" --destination=\"$REAL_DEST\" apply --verbose --debug"
    if command_exists strace; then
        echo "ℹ️  strace detected; tracing real apply to /tmp/chezmoi-apply-real.strace.log" | tee -a "$LOG_FILE"
        run_test_suite "ChezMoi Apply (real in temp HOME, traced)" "strace -f -tt -s 200 -o /tmp/chezmoi-apply-real.strace.log $REAL_CMD"
    else
        run_test_suite "ChezMoi Apply (real in temp HOME)" "$REAL_CMD"
    fi
    # Run a second real-apply with pager explicitly enabled to detect pager-related stalls under timeout.
    run_test_suite "ChezMoi Apply (real in temp HOME, pager ON)" "env CHEZMOI_ENABLE_PAGER=1 $REAL_CMD"
    # Post-apply status snapshot in the temp HOME
    run_test_suite "ChezMoi Status (real temp HOME)" "env HOME=$TEMPHOME XDG_CONFIG_HOME=$XDG_CONFIG_HOME XDG_DATA_HOME=$XDG_DATA_HOME XDG_STATE_HOME=$XDG_STATE_HOME XDG_CACHE_HOME=$XDG_CACHE_HOME chezmoi --source=\"$REAL_SRC\" --destination=\"$REAL_DEST\" status --verbose"
    # List key results from the temp home for debugging context
    {
      echo "[diag] Temp HOME: $TEMPHOME"
      echo "[diag] Temp HOME tree (top-level):"; ls -la "$TEMPHOME" || true
      echo "[diag] Temp XDG config tree (top 2 levels):"; find "$XDG_CONFIG_HOME" -maxdepth 2 -type d -print | sed -n '1,50p' || true
    } >> "$LOG_FILE" 2>&1
    # Verify that important files were actually materialized into the temp HOME
    verify_materialization "$TEMPHOME"
    # Remove trap; perform explicit cleanup to avoid leaving temp dirs in CI logs
    trap - EXIT
    cleanup_temp_home_layer
fi

# Multiuser validation (two users; zsh then bash) with wrapper presence and timeouts
multiuser_test_flow

# Generate test report
echo "" | tee -a "$LOG_FILE"
echo "📊 Test Summary" | tee -a "$LOG_FILE"
echo "===============" | tee -a "$LOG_FILE"
echo "📅 Completed: $(date)" | tee -a "$LOG_FILE"
echo "📝 Log file: $LOG_FILE" | tee -a "$LOG_FILE"
echo "🖥️  Environment: DevContainer" | tee -a "$LOG_FILE"
echo "🐚 Available shells: $(which bash zsh 2>/dev/null | tr '\n' ' ')" | tee -a "$LOG_FILE"
echo "🧪 Bats version: $(bats --version 2>/dev/null || echo 'N/A')" | tee -a "$LOG_FILE"

# Print full log to stdout for CI visibility
echo "==== Begin Test Log ===="
cat "$LOG_FILE" || true
echo "==== End Test Log ===="

# If an strace log was captured for chezmoi apply, surface the tail for quick diagnostics
echo "[diag] Checking for strace log at /tmp/chezmoi-apply.strace.log" | tee -a "$LOG_FILE"
if [ -f "/tmp/chezmoi-apply.strace.log" ]; then
  echo "==== Tail of /tmp/chezmoi-apply.strace.log (last 200 lines) ===="
  tail -n 200 /tmp/chezmoi-apply.strace.log || true
  echo "==== End Tail of strace log ===="
else
  echo "[diag] No strace log found." | tee -a "$LOG_FILE"
fi

# Surface tail of real-apply strace, if captured
if [ -f "/tmp/chezmoi-apply-real.strace.log" ]; then
  echo "==== Tail of /tmp/chezmoi-apply-real.strace.log (last 200 lines) ===="
  tail -n 200 /tmp/chezmoi-apply-real.strace.log || true
  echo "==== End Tail of real-apply strace log ===="
fi

# Check for any failures in the log
echo "[diag] Scanning log for failure markers ([FAIL] or [TIMEOUT])" | tee -a "$LOG_FILE"
FAIL_DETECTED=0
EXIT_RC=0
if command -v timeout >/dev/null 2>&1; then
  if timeout 3s env LC_ALL=C grep -qE '\\[FAIL\\]|\\[TIMEOUT\\]' "$LOG_FILE"; then
    FAIL_DETECTED=1
  else
    echo "[diag] ASCII marker scan clean; trying emoji scan with fallback locale" | tee -a "$LOG_FILE"
    timeout 2s env LC_ALL=C.UTF-8 grep -qE '❌|⏳' "$LOG_FILE" && FAIL_DETECTED=1 || true
  fi
else
  env LC_ALL=C grep -qE '\\[FAIL\\]|\\[TIMEOUT\\]' "$LOG_FILE" && FAIL_DETECTED=1 || true
fi

# Combine with in-process flags recorded by run_test_suite()
if [ "$TEST_FAILURES" -eq 1 ] || [ "$TIMEOUTS_DETECTED" -eq 1 ]; then
  FAIL_DETECTED=1
fi

if [ "$FAIL_DETECTED" -eq 1 ]; then
    echo "" | tee -a "$LOG_FILE"
    echo "⚠️  Some tests failed. Check the log for details." | tee -a "$LOG_FILE"
    EXIT_RC=1
    echo "==== Failure markers (last 80) ===="
    if command -v timeout >/dev/null 2>&1; then
      if ! timeout 3s env LC_ALL=C grep -nE '\\[FAIL\\]|\\[TIMEOUT\\]' "$LOG_FILE" | tail -n 80; then
		echo "==== include emoji scan ===="
        timeout 2s env LC_ALL=C.UTF-8 grep -nE '❌|⏳' "$LOG_FILE" | tail -n 80 || true
      fi
    else
		echo "==== timeout not available ===="
      env LC_ALL=C grep -nE '\\[FAIL\\]|\\[TIMEOUT\\]' "$LOG_FILE" | tail -n 80 || true
    fi
    echo "==== End Failure markers ===="
 else
    echo "" | tee -a "$LOG_FILE"
    echo "🎉 All tests passed successfully!" | tee -a "$LOG_FILE"
 fi
 echo "" | tee -a "$LOG_FILE"
 echo "[diag] Printing manual run hints" | tee -a "$LOG_FILE"
echo "💡 To run tests manually:" | tee -a "$LOG_FILE"
echo "   bats scripts/tests/shell-tests.bats" | tee -a "$LOG_FILE"
echo "   DEBUG_MODULE_LOADING=1 zsh" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"
echo "[diag] Attempting to persist logs (workspace: $WORKSPACE_DIR)" | tee -a "$LOG_FILE"
if [ -w "$WORKSPACE_DIR" ]; then
  echo "[diag] Workspace is writable; ensuring $WORKSPACE_DIR/tmp/logs exists" | tee -a "$LOG_FILE"
  mkdir -p "$WORKSPACE_DIR/tmp/logs" 2>/dev/null || true
  echo "[diag] Copying log to $WORKSPACE_DIR/tmp/logs" | tee -a "$LOG_FILE"
  cp "$LOG_FILE" "$WORKSPACE_DIR/tmp/logs/" 2>/dev/null || true
  echo "📝 Log persisted to: $WORKSPACE_DIR/tmp/logs/$(basename "$LOG_FILE")" | tee -a "$LOG_FILE"
else
  echo "ℹ️  Workspace is not writable; skipped persisting logs to $WORKSPACE_DIR/tmp/logs" | tee -a "$LOG_FILE"
fi

exit "$EXIT_RC"
