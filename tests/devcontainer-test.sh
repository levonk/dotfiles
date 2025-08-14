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
WORKSPACE_DIR="/workspace"
TESTS_DIR="$WORKSPACE_DIR/tests"
BATS_TEST_FILE="$TESTS_DIR/shell-tests.bats"
LOG_FILE="/tmp/dotfiles-test-$(date +%Y%m%d-%H%M%S).log"

echo "🧪 Starting automated dotfiles testing..." | tee "$LOG_FILE"
echo "📅 Test run: $(date)" | tee -a "$LOG_FILE"
echo "🖥️  Container: $(hostname)" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"

# Function to run tests with timing
run_test_suite() {
    local test_name="$1"
    local test_command="$2"
    
    echo "🔍 Running $test_name..." | tee -a "$LOG_FILE"
    local start_time=$(date +%s.%N)
    
    if eval "$test_command" >> "$LOG_FILE" 2>&1; then
        local end_time=$(date +%s.%N)
        local duration=$(echo "$end_time - $start_time" | bc -l 2>/dev/null || echo "N/A")
        echo "✅ $test_name completed successfully (${duration}s)" | tee -a "$LOG_FILE"
        return 0
    else
        local end_time=$(date +%s.%N)
        local duration=$(echo "$end_time - $start_time" | bc -l 2>/dev/null || echo "N/A")
        echo "❌ $test_name failed (${duration}s)" | tee -a "$LOG_FILE"
        return 1
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
run_test_suite "Shell Configuration Tests" "cd '$WORKSPACE_DIR' && bats '$BATS_TEST_FILE'"

# Test 2: Shell startup performance (bash)
run_test_suite "Bash Startup Performance" "time bash -c 'source ~/.bashrc && exit'"

# Test 3: Shell startup performance (zsh)
run_test_suite "Zsh Startup Performance" "time zsh -c 'source ~/.zshrc && exit'"

# Test 4: Git configuration validation
if [ -f "$HOME/.config/git/public-vcs.toml" ]; then
    run_test_suite "Git Configuration Validation" "cd '$WORKSPACE_DIR' && git config --list | head -20"
else
    echo "⚠️  Git configuration not found, skipping validation" | tee -a "$LOG_FILE"
fi

# Test 5: Local bin scripts validation
if [ -d "$HOME/.local/bin" ] && [ "$(ls -A $HOME/.local/bin)" ]; then
    run_test_suite "Local Scripts Validation" "ls -la '$HOME/.local/bin' && file '$HOME/.local/bin/'*"
else
    echo "⚠️  No local bin scripts found, skipping validation" | tee -a "$LOG_FILE"
fi

# Test 6: Platform detection
if [ -f "$HOME/.config/shells/shared/util/platform-detection.sh" ]; then
    run_test_suite "Platform Detection" "source '$HOME/.config/shells/shared/util/platform-detection.sh' && echo 'Platform: $DOTFILES_PLATFORM'"
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
