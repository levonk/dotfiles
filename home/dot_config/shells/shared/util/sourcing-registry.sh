#!/bin/bash
# Sourcing Registry and Guards Utility
# Purpose: Prevent redundant sourcing of configuration files and track loaded modules
# Shell Support: bash, zsh (POSIX-compliant)
# Chezmoi: Managed by chezmoi, safe to source multiple times
# Security: No external calls, safe for all environments
# Extensibility: Can be extended to track timing and dependencies

# Global registry to track sourced files
declare -A DOTFILES_SOURCED_REGISTRY 2>/dev/null || {
    # Fallback for shells without associative arrays
    DOTFILES_SOURCED_REGISTRY=""
}

# Performance timing registry
declare -A DOTFILES_TIMING_REGISTRY 2>/dev/null || {
    DOTFILES_TIMING_REGISTRY=""
}

# Check if a file has already been sourced
# Usage: is_already_sourced "/path/to/file.sh"
# Returns: 0 if already sourced, 1 if not sourced
is_already_sourced() {
    local file_path="$1"
    local canonical_path
    
    # Validate input
    if [ -z "$file_path" ]; then
        echo "Error: is_already_sourced requires a file path" >&2
        return 2
    fi
    
    # Get canonical path to handle symlinks and relative paths
    if command -v realpath >/dev/null 2>&1; then
        canonical_path="$(realpath "$file_path" 2>/dev/null)" || canonical_path="$file_path"
    else
        canonical_path="$file_path"
    fi
    
    # Check registry (handle both associative array and fallback)
    if [ -n "${DOTFILES_SOURCED_REGISTRY[$canonical_path]:-}" ] 2>/dev/null; then
        return 0  # Already sourced
    elif echo "$DOTFILES_SOURCED_REGISTRY" | grep -q "$canonical_path" 2>/dev/null; then
        return 0  # Already sourced (fallback method)
    else
        return 1  # Not sourced
    fi
}

# Mark a file as sourced in the registry
# Usage: mark_as_sourced "/path/to/file.sh"
mark_as_sourced() {
    local file_path="$1"
    local canonical_path
    local timestamp
    
    # Validate input
    if [ -z "$file_path" ]; then
        echo "Error: mark_as_sourced requires a file path" >&2
        return 2
    fi
    
    # Get canonical path
    if command -v realpath >/dev/null 2>&1; then
        canonical_path="$(realpath "$file_path" 2>/dev/null)" || canonical_path="$file_path"
    else
        canonical_path="$file_path"
    fi
    
    # Get timestamp for tracking
    timestamp="$(date +%s 2>/dev/null)" || timestamp="unknown"
    
    # Mark as sourced (handle both associative array and fallback)
    if [ -n "${DOTFILES_SOURCED_REGISTRY+x}" ] 2>/dev/null; then
        DOTFILES_SOURCED_REGISTRY["$canonical_path"]="$timestamp"
    else
        # Fallback for shells without associative arrays
        DOTFILES_SOURCED_REGISTRY="$DOTFILES_SOURCED_REGISTRY $canonical_path:$timestamp"
    fi
}

# Safe sourcing with redundancy protection
# Usage: safe_source "/path/to/file.sh" ["description"]
safe_source() {
    local file_path="$1"
    local description="${2:-$(basename "$file_path")}"
    local start_time end_time duration
    
    # Validate input
    if [ -z "$file_path" ]; then
        echo "Error: safe_source requires a file path" >&2
        return 2
    fi
    
    # Check if already sourced
    if is_already_sourced "$file_path"; then
        # Optional debug output (only if DEBUG_SOURCING is set)
        if [ -n "${DEBUG_SOURCING:-}" ]; then
            echo "Debug: Skipping already sourced file: $description" >&2
        fi
        return 0
    fi
    
    # Validate file exists and is readable
    if [ ! -r "$file_path" ]; then
        echo "Warning: Cannot source $description - file not readable: $file_path" >&2
        return 1
    fi
    
    # Record start time for performance tracking
    if command -v date >/dev/null 2>&1; then
        start_time="$(date +%s%3N 2>/dev/null)" || start_time="$(date +%s)"
    fi
    
    # Source the file
    if . "$file_path"; then
        # Mark as successfully sourced
        mark_as_sourced "$file_path"
        
        # Record timing if available
        if [ -n "$start_time" ] && command -v date >/dev/null 2>&1; then
            end_time="$(date +%s%3N 2>/dev/null)" || end_time="$(date +%s)"
            duration=$((end_time - start_time))
            
            # Store timing (handle both associative array and fallback)
            if [ -n "${DOTFILES_TIMING_REGISTRY+x}" ] 2>/dev/null; then
                DOTFILES_TIMING_REGISTRY["$file_path"]="$duration"
            fi
            
            # Optional performance warning
            if [ -n "${DEBUG_SOURCING:-}" ] && [ "$duration" -gt 100 ]; then
                echo "Performance: $description took ${duration}ms to source" >&2
            fi
        fi
        
        return 0
    else
        echo "Error: Failed to source $description: $file_path" >&2
        return 1
    fi
}

# Get sourcing statistics
# Usage: get_sourcing_stats
get_sourcing_stats() {
    local count=0
    local total_time=0
    
    echo "=== Dotfiles Sourcing Statistics ==="
    
    # Count sourced files
    if [ -n "${DOTFILES_SOURCED_REGISTRY+x}" ] 2>/dev/null; then
        for file in "${!DOTFILES_SOURCED_REGISTRY[@]}"; do
            count=$((count + 1))
            echo "  ✓ $file (${DOTFILES_SOURCED_REGISTRY[$file]})"
        done
    else
        # Fallback counting
        count=$(echo "$DOTFILES_SOURCED_REGISTRY" | wc -w)
        echo "  Files sourced: $count"
    fi
    
    echo "Total files sourced: $count"
    
    # Show timing information if available
    if [ -n "${DOTFILES_TIMING_REGISTRY+x}" ] 2>/dev/null; then
        echo "=== Performance Timing ==="
        for file in "${!DOTFILES_TIMING_REGISTRY[@]}"; do
            local time="${DOTFILES_TIMING_REGISTRY[$file]}"
            total_time=$((total_time + time))
            echo "  $file: ${time}ms"
        done
        echo "Total sourcing time: ${total_time}ms"
    fi
}

# Clear the sourcing registry (useful for testing)
# Usage: clear_sourcing_registry
clear_sourcing_registry() {
    if [ -n "${DOTFILES_SOURCED_REGISTRY+x}" ] 2>/dev/null; then
        unset DOTFILES_SOURCED_REGISTRY
        declare -A DOTFILES_SOURCED_REGISTRY 2>/dev/null
    else
        DOTFILES_SOURCED_REGISTRY=""
    fi
    
    if [ -n "${DOTFILES_TIMING_REGISTRY+x}" ] 2>/dev/null; then
        unset DOTFILES_TIMING_REGISTRY
        declare -A DOTFILES_TIMING_REGISTRY 2>/dev/null
    else
        DOTFILES_TIMING_REGISTRY=""
    fi
}

# Export functions for use in other scripts
if [ -n "${BASH_VERSION:-}" ]; then
    export -f is_already_sourced mark_as_sourced safe_source get_sourcing_stats clear_sourcing_registry
fi
