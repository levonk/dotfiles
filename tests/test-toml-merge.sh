#!/bin/bash
# =====================================================================
# Test Script for TOML Merge Tool and git-vcs-config.sh Integration
# Managed by chezmoi | https://github.com/levonk/dotfiles
#
# Purpose:
#   - Test the new toml-merge.sh tool functionality
#   - Verify git-vcs-config.sh integration works correctly
#   - Validate TOML parsing and merging capabilities
#
# Usage: ./test-toml-merge.sh
# =====================================================================

set -euo pipefail

# Variables for DRY principle
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
TOML_MERGE_TOOL="$PROJECT_ROOT/home/dot_local/bin/toml-merge.sh"
GIT_VCS_CONFIG="$PROJECT_ROOT/home/dot_local/bin/git-vcs-config.sh"
TEST_DIR="/tmp/toml-merge-test-$$"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Test counters
TESTS_PASSED=0
TESTS_FAILED=0

# =============================================================================
# Test Helper Functions
# =============================================================================

log_info() {
    echo -e "${BLUE}[TEST-INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[TEST-PASS]${NC} $1"
    ((TESTS_PASSED++))
}

log_error() {
    echo -e "${RED}[TEST-FAIL]${NC} $1"
    ((TESTS_FAILED++))
}

log_warning() {
    echo -e "${YELLOW}[TEST-WARN]${NC} $1"
}

# Test assertion function
assert_equals() {
    local expected="$1"
    local actual="$2"
    local test_name="$3"
    
    if [[ "$expected" == "$actual" ]]; then
        log_success "$test_name: Expected '$expected', got '$actual'"
    else
        log_error "$test_name: Expected '$expected', got '$actual'"
    fi
}

# =============================================================================
# Test Setup
# =============================================================================

setup_test_environment() {
    log_info "Setting up test environment in $TEST_DIR"
    
    # Create test directory
    mkdir -p "$TEST_DIR"
    
    # Create test TOML files
    cat > "$TEST_DIR/config.toml" << 'EOF'
# Test configuration file
[general]
repo_base = "/home/user/repos"
default_branch = "main"

[accounts.github]
protocol = "ssh"
host_alias = "gh"

[accounts.github.user]
name = "Test User"
email = "test@example.com"

[accounts.gitlab]
protocol = "https"
host_alias = "gl"
EOF

    cat > "$TEST_DIR/user.toml" << 'EOF'
# User-specific overrides
[general]
repo_base = "/home/user/projects"

[accounts.github.user]
name = "User Override"
email = "user@override.com"

[accounts.bitbucket]
protocol = "ssh"
host_alias = "bb"
EOF

    log_info "Test files created successfully"
}

cleanup_test_environment() {
    log_info "Cleaning up test environment"
    rm -rf "$TEST_DIR"
}

# =============================================================================
# TOML Merge Tool Tests
# =============================================================================

test_toml_merge_basic() {
    log_info "Testing basic TOML merge functionality"
    
    # Test single file parsing
    local result
    result=$("$TOML_MERGE_TOOL" get "$TEST_DIR/config.toml" "general.repo_base" "default")
    assert_equals "/home/user/repos" "$result" "Single file basic key"
    
    # Test nested key parsing
    result=$("$TOML_MERGE_TOOL" get "$TEST_DIR/config.toml" "accounts.github.user.name" "default")
    assert_equals "Test User" "$result" "Single file nested key"
    
    # Test default value
    result=$("$TOML_MERGE_TOOL" get "$TEST_DIR/config.toml" "nonexistent.key" "default_value")
    assert_equals "default_value" "$result" "Default value fallback"
}

test_toml_merge_priority() {
    log_info "Testing TOML merge priority (first file wins)"
    
    # Test that user.toml overrides config.toml
    local result
    result=$("$TOML_MERGE_TOOL" get "$TEST_DIR/user.toml" "$TEST_DIR/config.toml" "general.repo_base" "default")
    assert_equals "/home/user/projects" "$result" "Priority merge - user overrides config"
    
    # Test that user.toml overrides specific nested key
    result=$("$TOML_MERGE_TOOL" get "$TEST_DIR/user.toml" "$TEST_DIR/config.toml" "accounts.github.user.name" "default")
    assert_equals "User Override" "$result" "Priority merge - nested key override"
    
    # Test fallback to second file when key not in first
    result=$("$TOML_MERGE_TOOL" get "$TEST_DIR/user.toml" "$TEST_DIR/config.toml" "accounts.github.protocol" "default")
    assert_equals "ssh" "$result" "Priority merge - fallback to second file"
}

test_toml_merge_validation() {
    log_info "Testing TOML validation functionality"
    
    # Test valid files
    if "$TOML_MERGE_TOOL" validate "$TEST_DIR/config.toml" "$TEST_DIR/user.toml" >/dev/null 2>&1; then
        log_success "TOML validation - valid files pass"
    else
        log_error "TOML validation - valid files should pass"
    fi
    
    # Create invalid TOML file
    cat > "$TEST_DIR/invalid.toml" << 'EOF'
[section
invalid = line
key = "unclosed quote
EOF
    
    # Test invalid file
    if ! "$TOML_MERGE_TOOL" validate "$TEST_DIR/invalid.toml" >/dev/null 2>&1; then
        log_success "TOML validation - invalid files fail"
    else
        log_error "TOML validation - invalid files should fail"
    fi
}

# =============================================================================
# git-vcs-config.sh Integration Tests
# =============================================================================

test_git_vcs_config_integration() {
    log_info "Testing git-vcs-config.sh integration with toml-merge.sh"
    
    # Set up environment variables for git-vcs-config.sh
    export GIT_VCS_CONFIG_FILE="$TEST_DIR/config.toml"
    export GIT_VCS_DATA_FILE="$TEST_DIR/user.toml"
    export DEBUG_VCS=1
    
    # Source git-vcs-config.sh
    if source "$GIT_VCS_CONFIG" 2>/dev/null; then
        log_success "git-vcs-config.sh sourced successfully"
    else
        log_error "Failed to source git-vcs-config.sh"
        return
    fi
    
    # Test parse_toml_value function
    local result
    result=$(parse_toml_value "$TEST_DIR/config.toml" "general.repo_base" "default")
    assert_equals "/home/user/repos" "$result" "git-vcs-config parse_toml_value"
    
    # Test _try_config_key function (should use toml-merge.sh)
    result=$(_try_config_key "general.repo_base")
    assert_equals "/home/user/projects" "$result" "git-vcs-config _try_config_key with merge"
    
    # Clean up environment
    unset GIT_VCS_CONFIG_FILE GIT_VCS_DATA_FILE DEBUG_VCS
}

# =============================================================================
# Performance Tests
# =============================================================================

test_performance_comparison() {
    log_info "Testing performance comparison (basic benchmark)"
    
    local start_time end_time duration
    
    # Test toml-merge.sh performance
    start_time=$(date +%s.%N)
    for i in {1..10}; do
        "$TOML_MERGE_TOOL" get "$TEST_DIR/user.toml" "$TEST_DIR/config.toml" "accounts.github.user.name" "default" >/dev/null
    done
    end_time=$(date +%s.%N)
    duration=$(echo "$end_time - $start_time" | bc -l 2>/dev/null || echo "N/A")
    
    log_info "toml-merge.sh: 10 operations in ${duration}s"
    
    # Test fallback parser performance
    export GIT_VCS_CONFIG_FILE="$TEST_DIR/config.toml"
    export GIT_VCS_DATA_FILE="$TEST_DIR/user.toml"
    source "$GIT_VCS_CONFIG" 2>/dev/null
    
    start_time=$(date +%s.%N)
    for i in {1..10}; do
        parse_toml_value "$TEST_DIR/config.toml" "accounts.github.user.name" "default" >/dev/null
    done
    end_time=$(date +%s.%N)
    duration=$(echo "$end_time - $start_time" | bc -l 2>/dev/null || echo "N/A")
    
    log_info "Fallback parser: 10 operations in ${duration}s"
    
    unset GIT_VCS_CONFIG_FILE GIT_VCS_DATA_FILE
}

# =============================================================================
# Main Test Runner
# =============================================================================

main() {
    log_info "Starting TOML merge tool and git-vcs-config.sh integration tests"
    log_info "=============================================================="
    
    # Check prerequisites
    if [[ ! -f "$TOML_MERGE_TOOL" ]]; then
        log_error "toml-merge.sh not found at $TOML_MERGE_TOOL"
        exit 1
    fi
    
    if [[ ! -f "$GIT_VCS_CONFIG" ]]; then
        log_error "git-vcs-config.sh not found at $GIT_VCS_CONFIG"
        exit 1
    fi
    
    # Make sure tools are executable
    chmod +x "$TOML_MERGE_TOOL" 2>/dev/null || true
    
    # Set up test environment
    setup_test_environment
    
    # Run tests
    test_toml_merge_basic
    test_toml_merge_priority
    test_toml_merge_validation
    test_git_vcs_config_integration
    test_performance_comparison
    
    # Clean up
    cleanup_test_environment
    
    # Report results
    log_info "=============================================================="
    log_info "Test Results: $TESTS_PASSED passed, $TESTS_FAILED failed"
    
    if [[ $TESTS_FAILED -eq 0 ]]; then
        log_success "All tests passed! 🎉"
        exit 0
    else
        log_error "Some tests failed. Please review the output above."
        exit 1
    fi
}

# Run tests if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
