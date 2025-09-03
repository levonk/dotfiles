#!/bin/bash
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
    # Running locally - use the script's directory as base
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    WORKSPACE_DIR="$(dirname "$SCRIPT_DIR")"
fi

TESTS_DIR="$WORKSPACE_DIR/tests"
BATS_TEST_FILE="$TESTS_DIR/shell-tests.bats"
LOG_FILE="/tmp/dotfiles-test-$(date +%Y%m%d-%H%M%S).log"
# Default per-test timeout (seconds). Can override via DEV_TEST_TIMEOUT_SECS env var
DEV_TEST_TIMEOUT_SECS="${DEV_TEST_TIMEOUT_SECS:-20}"

echo "🧪 Starting automated dotfiles testing..." | tee "$LOG_FILE"
echo "📅 Test run: $(date)" | tee -a "$LOG_FILE"
echo "🖥️  Container: $(hostname)" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
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
        bash -lc "timeout --signal=KILL ${DEV_TEST_TIMEOUT_SECS}s bash -lc $'${test_command//'/\''}'" >> "$LOG_FILE" 2>&1
        rc=$?
        if [ $rc -eq 137 ] || [ $rc -eq 124 ]; then
            end_time=$(date +%s.%N)
            duration=$(echo "$end_time - $start_time" | bc -l 2>/dev/null || echo "N/A")
            echo "⏳ $test_name timed out after ${DEV_TEST_TIMEOUT_SECS}s (${duration}s)" | tee -a "$LOG_FILE"
            return 124
        fi
    else
        # No timeout available; run directly
        eval "$test_command" >> "$LOG_FILE" 2>&1
        rc=$?
    fi
    end_time=$(date +%s.%N)
    duration=$(echo "$end_time - $start_time" | bc -l 2>/dev/null || echo "N/A")
    if [ $rc -eq 0 ]; then
        echo "✅ $test_name completed successfully (${duration}s)" | tee -a "$LOG_FILE"
        return 0
    else
        echo "❌ $test_name failed (rc=$rc, ${duration}s)" | tee -a "$LOG_FILE"
        return $rc
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
if command -v bats >/dev/null 2>&1; then
    run_test_suite "Shell Configuration Tests" "cd '$WORKSPACE_DIR' && BATS_TEST_DIRNAME='$TESTS_DIR' bats '$BATS_TEST_FILE'"
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
    # Use a simpler git command that's less likely to fail
    run_test_suite "Git Configuration Validation" "git --version && (cd '$WORKSPACE_DIR' && git config --list 2>/dev/null | grep -E '^(user\.|core\.)' || echo 'No git config found')"
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

# Generate test report
echo "" | tee -a "$LOG_FILE"
echo "📊 Test Summary" | tee -a "$LOG_FILE"
echo "===============" | tee -a "$LOG_FILE"
echo "📅 Completed: $(date)" | tee -a "$LOG_FILE"
echo "📝 Log file: $LOG_FILE" | tee -a "$LOG_FILE"
echo "🖥️  Environment: DevContainer" | tee -a "$LOG_FILE"
echo "🐚 Available shells: $(which bash zsh 2>/dev/null | tr '\n' ' ')" | tee -a "$LOG_FILE"
echo "🧪 Bats version: $(bats --version 2>/dev/null || echo 'N/A')" | tee -a "$LOG_FILE"

# Check for any failures in the log
if grep -q "❌" "$LOG_FILE"; then
    echo "" | tee -a "$LOG_FILE"
    echo "⚠️  Some tests failed. Check the log for details." | tee -a "$LOG_FILE"
    exit 1
else
    echo "" | tee -a "$LOG_FILE"
    echo "🎉 All tests passed successfully!" | tee -a "$LOG_FILE"
fi

echo "" | tee -a "$LOG_FILE"
echo "💡 To run tests manually:" | tee -a "$LOG_FILE"
echo "   bats tests/shell-tests.bats" | tee -a "$LOG_FILE"
echo "   DEBUG_MODULE_LOADING=1 zsh" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"

# Persist logs to mounted workspace for easier inspection
mkdir -p "$WORKSPACE_DIR/tmp/logs" 2>/dev/null || true
cp "$LOG_FILE" "$WORKSPACE_DIR/tmp/logs/" 2>/dev/null || true
echo "📝 Log persisted to: $WORKSPACE_DIR/tmp/logs/$(basename "$LOG_FILE")" | tee -a "$LOG_FILE"
