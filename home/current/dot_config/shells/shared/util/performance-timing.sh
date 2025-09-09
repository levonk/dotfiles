# shellcheck shell=sh
#!/bin/bash
if [[ "" == "bash" ]]; then
  echo "ERROR: This script must be sourced, not executed."
  exit 1
fi
#!/bin/bash
# Performance Timing Utility for Dotfiles
# Purpose: Measure and track shell startup and sourcing performance
# Shell Support: bash, zsh (POSIX-compliant where possible)
# Chezmoi: Managed by chezmoi, safe to source multiple times
# Security: No external calls, safe for all environments
# Extensibility: Can be extended with profiling and bottleneck detection

# Performance tracking variables
DOTFILES_STARTUP_START_TIME=""
DOTFILES_PERFORMANCE_LOG="${XDG_CACHE_HOME:-$HOME/.cache}/dotfiles/performance.log"
DOTFILES_PERFORMANCE_ENABLED="${DOTFILES_PERFORMANCE_ENABLED:-0}"
DOTFILES_PERFORMANCE_THRESHOLD="${DOTFILES_PERFORMANCE_THRESHOLD:-100}"  # ms

# Timing registry for detailed breakdown
declare -A DOTFILES_TIMING_BREAKDOWN 2>/dev/null || {
    DOTFILES_TIMING_BREAKDOWN=""
}

# Initialize performance tracking
# Usage: init_performance_tracking
init_performance_tracking() {
    # Only enable if explicitly requested or in debug mode
    if [ -n "${DEBUG_SOURCING:-}" ] || [ "$DOTFILES_PERFORMANCE_ENABLED" = "1" ]; then
        DOTFILES_PERFORMANCE_ENABLED=1
        
        # Create performance log directory
        local log_dir
        log_dir="$(dirname "$DOTFILES_PERFORMANCE_LOG")"
        if [ ! -d "$log_dir" ]; then
            mkdir -p "$log_dir" 2>/dev/null || {
                echo "Warning: Could not create performance log directory: $log_dir" >&2
                DOTFILES_PERFORMANCE_ENABLED=0
                return 1
            }
        fi
        
        # Record startup start time
        if command -v date >/dev/null 2>&1; then
            DOTFILES_STARTUP_START_TIME="$(date +%s%3N 2>/dev/null)" || DOTFILES_STARTUP_START_TIME="$(date +%s)000"
        fi
        
        # Initialize log file with session header
        {
            echo "=== Dotfiles Performance Session: $(date 2>/dev/null || echo 'unknown') ==="
            echo "Shell: ${SHELL:-unknown}"
            echo "Performance threshold: ${DOTFILES_PERFORMANCE_THRESHOLD}ms"
            echo ""
        } >> "$DOTFILES_PERFORMANCE_LOG" 2>/dev/null
    fi
}

# Get high-resolution timestamp
# Usage: get_timestamp
get_timestamp() {
    if command -v date >/dev/null 2>&1; then
        # Try to get millisecond precision, fallback to seconds
        date +%s%3N 2>/dev/null || echo "$(($(date +%s) * 1000))"
    else
        echo "0"
    fi
}

# Start timing a section
# Usage: start_timing "section_name"
start_timing() {
    local section_name="$1"
    local timestamp
    
    if [ "$DOTFILES_PERFORMANCE_ENABLED" != "1" ] || [ -z "$section_name" ]; then
        return 0
    fi
    
    timestamp="$(get_timestamp)"
    
    # Store start time in registry
    if [ -n "${DOTFILES_TIMING_BREAKDOWN+x}" ] 2>/dev/null; then
        DOTFILES_TIMING_BREAKDOWN["${section_name}_start"]="$timestamp"
    else
        # Fallback for shells without associative arrays
        DOTFILES_TIMING_BREAKDOWN="$DOTFILES_TIMING_BREAKDOWN ${section_name}_start:$timestamp"
    fi
    
    if [ -n "${DEBUG_SOURCING:-}" ]; then
        echo "Debug: Started timing section '$section_name'" >&2
    fi
}

# End timing a section and log results
# Usage: end_timing "section_name" ["description"]
end_timing() {
    local section_name="$1"
    local description="${2:-$section_name}"
    local start_time end_time duration
    
    if [ "$DOTFILES_PERFORMANCE_ENABLED" != "1" ] || [ -z "$section_name" ]; then
        return 0
    fi
    
    end_time="$(get_timestamp)"
    
    # Get start time from registry
    if [ -n "${DOTFILES_TIMING_BREAKDOWN+x}" ] 2>/dev/null; then
        start_time="${DOTFILES_TIMING_BREAKDOWN[${section_name}_start]:-}"
    else
        # Fallback method
        start_time="$(echo "$DOTFILES_TIMING_BREAKDOWN" | grep "${section_name}_start:" | cut -d: -f2)"
    fi
    
    if [ -z "$start_time" ] || [ "$start_time" = "0" ]; then
        echo "Warning: No start time found for section '$section_name'" >&2
        return 1
    fi
    
    # Calculate duration
    duration=$((end_time - start_time))
    
    # Store duration in registry
    if [ -n "${DOTFILES_TIMING_BREAKDOWN+x}" ] 2>/dev/null; then
        DOTFILES_TIMING_BREAKDOWN["$section_name"]="$duration"
        unset DOTFILES_TIMING_BREAKDOWN["${section_name}_start"]
    else
        DOTFILES_TIMING_BREAKDOWN="$DOTFILES_TIMING_BREAKDOWN $section_name:$duration"
    fi
    
    # Log performance data
    log_performance "$section_name" "$duration" "$description"
    
    # Warn about slow sections
    if [ "$duration" -gt "$DOTFILES_PERFORMANCE_THRESHOLD" ]; then
        echo "Performance Warning: '$description' took ${duration}ms (threshold: ${DOTFILES_PERFORMANCE_THRESHOLD}ms)" >&2
    fi
    
    if [ -n "${DEBUG_SOURCING:-}" ]; then
        echo "Debug: Section '$section_name' completed in ${duration}ms" >&2
    fi
}

# Log performance data
# Usage: log_performance "section_name" "duration_ms" "description"
log_performance() {
    local section_name="$1"
    local duration="$2"
    local description="$3"
    local timestamp
    
    if [ "$DOTFILES_PERFORMANCE_ENABLED" != "1" ]; then
        return 0
    fi
    
    timestamp="$(date '+%H:%M:%S' 2>/dev/null || echo 'unknown')"
    
    # Append to performance log
    echo "[$timestamp] $section_name: ${duration}ms - $description" >> "$DOTFILES_PERFORMANCE_LOG" 2>/dev/null
}

# Time a command or function call
# Usage: time_command "command_name" command arg1 arg2 ...
time_command() {
    local command_name="$1"
    shift
    local start_time end_time duration
    
    if [ "$DOTFILES_PERFORMANCE_ENABLED" != "1" ] || [ -z "$command_name" ]; then
        # Just execute the command without timing
        "$@"
        return $?
    fi
    
    start_time="$(get_timestamp)"
    
    # Execute the command
    "$@"
    local exit_code=$?
    
    end_time="$(get_timestamp)"
    duration=$((end_time - start_time))
    
    # Log the timing
    log_performance "$command_name" "$duration" "Command execution"
    
    # Warn about slow commands
    if [ "$duration" -gt "$DOTFILES_PERFORMANCE_THRESHOLD" ]; then
        echo "Performance Warning: Command '$command_name' took ${duration}ms" >&2
    fi
    
    return $exit_code
}

# Complete startup timing and generate report
# Usage: complete_startup_timing
complete_startup_timing() {
    local total_startup_time
    
    if [ "$DOTFILES_PERFORMANCE_ENABLED" != "1" ] || [ -z "$DOTFILES_STARTUP_START_TIME" ]; then
        return 0
    fi
    
    # Calculate total startup time
    local end_time
    end_time="$(get_timestamp)"
    total_startup_time=$((end_time - DOTFILES_STARTUP_START_TIME))
    
    # Log total startup time
    log_performance "TOTAL_STARTUP" "$total_startup_time" "Complete shell startup"
    
    # Generate summary
    {
        echo ""
        echo "=== Startup Summary ==="
        echo "Total startup time: ${total_startup_time}ms"
        
        # Show breakdown if available
        if [ -n "${DOTFILES_TIMING_BREAKDOWN+x}" ] 2>/dev/null; then
            echo "Performance breakdown:"
            for section in "${!DOTFILES_TIMING_BREAKDOWN[@]}"; do
                # Skip start time entries
                if [[ "$section" != *"_start" ]]; then
                    echo "  $section: ${DOTFILES_TIMING_BREAKDOWN[$section]}ms"
                fi
            done
        fi
        
        echo ""
    } >> "$DOTFILES_PERFORMANCE_LOG" 2>/dev/null
    
    # Warn about slow startup
    if [ "$total_startup_time" -gt 500 ]; then
        echo "Performance Warning: Shell startup took ${total_startup_time}ms (recommended: <500ms)" >&2
    fi
    
    if [ -n "${DEBUG_SOURCING:-}" ]; then
        echo "Debug: Shell startup completed in ${total_startup_time}ms" >&2
    fi
}

# Get performance statistics
# Usage: get_performance_stats
get_performance_stats() {
    echo "=== Dotfiles Performance Statistics ==="
    echo "Performance tracking: $DOTFILES_PERFORMANCE_ENABLED"
    echo "Performance threshold: ${DOTFILES_PERFORMANCE_THRESHOLD}ms"
    echo "Performance log: $DOTFILES_PERFORMANCE_LOG"
    
    if [ "$DOTFILES_PERFORMANCE_ENABLED" = "1" ] && [ -f "$DOTFILES_PERFORMANCE_LOG" ]; then
        echo ""
        echo "=== Recent Performance Data ==="
        tail -20 "$DOTFILES_PERFORMANCE_LOG" 2>/dev/null || echo "No performance data available"
    fi
    
    # Show current timing breakdown
    if [ -n "${DOTFILES_TIMING_BREAKDOWN+x}" ] 2>/dev/null; then
        echo ""
        echo "=== Current Session Breakdown ==="
        for section in "${!DOTFILES_TIMING_BREAKDOWN[@]}"; do
            if [[ "$section" != *"_start" ]]; then
                echo "  $section: ${DOTFILES_TIMING_BREAKDOWN[$section]}ms"
            fi
        done
    fi
}

# Analyze performance bottlenecks
# Usage: analyze_performance_bottlenecks
analyze_performance_bottlenecks() {
    if [ "$DOTFILES_PERFORMANCE_ENABLED" != "1" ] || [ ! -f "$DOTFILES_PERFORMANCE_LOG" ]; then
        echo "Performance tracking not enabled or no data available"
        return 1
    fi
    
    echo "=== Performance Bottleneck Analysis ==="
    
    # Find slowest operations
    echo "Slowest operations (>100ms):"
    grep -E ': [0-9]{3,}ms' "$DOTFILES_PERFORMANCE_LOG" 2>/dev/null | \
        sort -t: -k2 -nr | head -10 | \
        sed 's/^/  /'
    
    # Find frequently slow operations
    echo ""
    echo "Frequently slow sections:"
    grep -E ': [0-9]{3,}ms' "$DOTFILES_PERFORMANCE_LOG" 2>/dev/null | \
        cut -d' ' -f2 | cut -d: -f1 | sort | uniq -c | sort -nr | head -5 | \
        sed 's/^/  /'
}

# Clear performance data
# Usage: clear_performance_data
clear_performance_data() {
    if [ -f "$DOTFILES_PERFORMANCE_LOG" ]; then
        rm -f "$DOTFILES_PERFORMANCE_LOG"
        echo "Performance log cleared"
    fi
    
    # Clear current session data
    if [ -n "${DOTFILES_TIMING_BREAKDOWN+x}" ] 2>/dev/null; then
        unset DOTFILES_TIMING_BREAKDOWN
        declare -A DOTFILES_TIMING_BREAKDOWN 2>/dev/null
    else
        DOTFILES_TIMING_BREAKDOWN=""
    fi
}

# Export functions for use in other scripts
if [ -n "${BASH_VERSION:-}" ]; then
    export -f init_performance_tracking get_timestamp start_timing end_timing log_performance time_command complete_startup_timing get_performance_stats analyze_performance_bottlenecks clear_performance_data
fi
