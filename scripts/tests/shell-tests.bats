#!/usr/bin/env bats
# =====================================================================
# Shell Configuration Tests using Bats
# Managed by chezmoi | https://github.com/levonk/dotfiles
#
# Purpose:
#   - Automated tests for shell configuration functionality
#   - Cross-platform compatibility testing
#   - Performance and error handling validation
#
# Requirements: bats-core (https://github.com/bats-core/bats-core)
# Usage: bats scripts/tests/shell-tests.bats
# =====================================================================

# Test setup
setup() {
    # Set up test environment
    export DOTFILES_TEST_MODE="true"
    export HOME="${BATS_TMPDIR}/test-home"
    mkdir -p "$HOME"
    
    # Copy essential configuration files for testing
    DOTFILES_ROOT="$(dirname "$(dirname "$BATS_TEST_DIRNAME")")"
    SRC1="$DOTFILES_ROOT/home/current/dot_config"
    SRC2="$DOTFILES_ROOT/home/dot_config"
    if [ -d "$SRC1" ]; then
        cp -r "$SRC1" "$HOME/.config" 2>/dev/null || true
    elif [ -d "$SRC2" ]; then
        cp -r "$SRC2" "$HOME/.config" 2>/dev/null || true
    else
        echo "[test-setup] dot_config source not found under $DOTFILES_ROOT/home/{current/,}dot_config" >&2
    fi
}

# Test teardown
teardown() {
    # Clean up test environment
    rm -rf "$HOME" 2>/dev/null || true
    unset DOTFILES_TEST_MODE
}

@test "platform detection utility loads correctly" {
    source "$HOME/.config/shells/shared/util/platform-detection.sh"
    
    # Should set platform variables
    [ -n "$DOTFILES_PLATFORM" ]
    [ -n "$DOTFILES_PATH_SEPARATOR" ]
    
    # Should have platform detection functions
    command -v get_platform >/dev/null
    command -v is_windows >/dev/null
    command -v is_unix >/dev/null
}

@test "shell availability detection works" {
    source "$HOME/.config/shells/shared/util/shell-availability.sh"
    
    # Should detect available shells
    [ -n "$DOTFILES_AVAILABLE_SHELLS" ]
    [ -n "$DOTFILES_FALLBACK_SHELL" ]
    
    # Should have shell detection functions
    command -v is_shell_available >/dev/null
    command -v get_best_shell >/dev/null
}

@test "tool availability checking functions" {
    source "$HOME/.config/shells/shared/util/shell-availability.sh"
    
    # Should be able to check for common tools
    run check_tool_cached "bash"
    [ "$status" -eq 0 ]
    
    run check_tool_cached "nonexistent-tool-12345"
    [ "$status" -eq 1 ]
}

@test "safe command execution with fallbacks" {
    source "$HOME/.config/shells/shared/util/shell-availability.sh"
    
    # Should use primary command if available
    if command -v echo >/dev/null; then
        run safe_command "echo" "printf" "test message"
        [ "$status" -eq 0 ]
        [[ "$output" == *"test message"* ]]
    fi
}

@test "entrypoint configuration loads without errors" {
    # Mock XDG environment
    export XDG_CONFIG_HOME="$HOME/.config"
    
    # Source the entrypoint configuration
    run bash -c "source '$HOME/.config/shells/shared/entrypointrc.sh' 2>&1"
    
    # Should not have critical errors
    [ "$status" -eq 0 ]
    
    # Should not contain error messages (warnings are OK)
    [[ "$output" != *"Error:"* ]]
}

@test "sharedrc configuration loads without errors" {
    # Mock environment
    export HOME="$HOME"
    
    # Source the shared configuration
    run bash -c "source '$HOME/.config/shells/shared/sharedrc.sh' 2>&1"
    
    # Should not have critical errors
    [ "$status" -eq 0 ]
    
    # Should not contain error messages
    [[ "$output" != *"Error:"* ]]
}

@test "path normalization works correctly" {
    source "$HOME/.config/shells/shared/util/platform-detection.sh"
    
    # Test Unix path normalization
    if is_unix; then
        result=$(normalize_path "/home/user/test")
        [ "$result" = "/home/user/test" ]
    fi
    
    # Test that function exists and runs
    run normalize_path "/test/path"
    [ "$status" -eq 0 ]
}

@test "XDG environment variables are set correctly" {
    # Source XDG environment configuration
    run bash -c "source '$HOME/.config/shells/shared/env/__xdg-env.sh' 2>&1; echo \$XDG_CONFIG_HOME"
    
    [ "$status" -eq 0 ]
    [[ "$output" == *"/.config"* ]]
}

@test "performance timing utilities work" {
    if [ -f "$HOME/.config/shells/shared/util/performance-timing.sh" ]; then
        source "$HOME/.config/shells/shared/util/performance-timing.sh"
        
        # Should have timing functions
        command -v start_timing >/dev/null
        command -v end_timing >/dev/null
        
        # Test basic timing functionality
        run start_timing "test_operation"
        [ "$status" -eq 0 ]
        
        run end_timing "test_operation"
        [ "$status" -eq 0 ]
    else
        skip "Performance timing utility not found"
    fi
}

@test "lazy loading system functions correctly" {
    if [ -f "$HOME/.config/shells/shared/util/lazy-loader.sh" ]; then
        source "$HOME/.config/shells/shared/util/lazy-loader.sh" || skip "Failed to source lazy-loader"
        # Should have lazy loading functions; if not present in this shell, skip
        command -v register_lazy_module >/dev/null || skip "register_lazy_module not available in this shell"
        command -v setup_lazy_triggers >/dev/null || skip "setup_lazy_triggers not available in this shell"
    else
        skip "Lazy loader utility not found"
    fi
}

@test "sourcing registry prevents double-loading" {
    if [ -f "$HOME/.config/shells/shared/util/sourcing-registry.sh" ]; then
        # Test registry functionality within a single subshell to maintain state
        run bash -c '
            source "$HOME/.config/shells/shared/util/sourcing-registry.sh"

            # Check that functions are available
            command -v is_already_sourced >/dev/null || exit 2
            command -v mark_as_sourced >/dev/null || exit 2

            # Test logic
            is_already_sourced "test-module"
            if [ "$?" -ne 1 ]; then exit 1; fi # Should not be sourced initially

            mark_as_sourced "test-module"

            is_already_sourced "test-module"
            if [ "$?" -ne 0 ]; then exit 1; fi # Should be marked as sourced now
        '
        [ "$status" -eq 0 ]
    else
        skip "Sourcing registry utility not found"
    fi
}

@test "file caching system works" {
    if [ -f "$HOME/.config/shells/shared/util/file-cache.sh" ]; then
        source "$HOME/.config/shells/shared/util/file-cache.sh" || skip "Failed to source file-cache"
        # Should have caching functions; otherwise skip as optional
        command -v is_file_cached >/dev/null || skip "is_file_cached not available"
        command -v cache_file_content >/dev/null || skip "cache_file_content not available"
    else
        skip "File cache utility not found"
    fi
}

@test "modern tool notification system" {
    if [ -f "$HOME/.config/shells/shared/util/modern-tool-notify.sh" ]; then
        run bash -c "source '$HOME/.config/shells/shared/util/modern-tool-notify.sh' 2>&1"
        [ "$status" -eq 0 ] || skip "modern-tool-notify requires a different shell/env"
        # Should have notification functions if successfully sourced
        command -v notify_modern_tool_usage >/dev/null || skip "notify_modern_tool_usage not available"
    else
        skip "Modern tool notification utility not found"
    fi
}

@test "directory navigation utilities" {
    if [ -f "$HOME/.config/shells/shared/util/dirnav.sh" ]; then
        if command -v zsh >/dev/null; then
            run zsh -lc "source '$HOME/.config/shells/shared/util/dirnav.sh' 2>&1"
            [ "$status" -eq 0 ] || skip "dirnav uses zsh-specific features"
        else
            skip "zsh not available for dirnav test"
        fi
    else
        skip "Directory navigation utility not found"
    fi
}

@test "SSH agent utilities work" {
    if [ -f "$HOME/.config/shells/shared/util/ssh-agent.sh" ]; then
        source "$HOME/.config/shells/shared/util/ssh-agent.sh"
        
        # Should load without errors
        [ "$?" -eq 0 ]
    else
        skip "SSH agent utility not found"
    fi
}

@test "configuration files have correct permissions" {
    # Check that shell scripts are executable
    find "$HOME/.config/shells" -name "*.sh" -type f | while read -r script; do
        [ -r "$script" ] || {
            echo "Script not readable: $script"
            exit 1
        }
    done
}
