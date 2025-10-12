#!/usr/bin/env sh
# shellcheck shell=sh

# =============================================================================
# 99-finalization.sh
#
# ## Purpose
#
# - Performs final cleanup and reporting tasks at the end of shell startup.
# - Cleans old cache files, sets up performance-related aliases, and generates
#   a final performance report if debugging is enabled.
# =============================================================================

start_timing "cleanup_and_reporting"

# Clean old cache files periodically
if command -v clean_cache >/dev/null 2>&1; then
    # Use a simple counter based on process ID modulo
    if [ $(($(echo $$ | tail -c 2) % 10)) -eq 0 ]; then
        clean_cache >/dev/null 2>&1 &
    fi
fi

# Provide helpful aliases for performance monitoring
if command -v get_performance_stats >/dev/null 2>&1; then
    alias dotfiles-perf='get_performance_stats'
    alias dotfiles-lazy='get_lazy_stats'
    alias dotfiles-cache='get_cache_stats'
    alias dotfiles-sourced='get_sourcing_stats'
    alias dotfiles-analyze='analyze_performance_bottlenecks'
fi

end_timing "cleanup_and_reporting" "Cleanup and reporting setup"

# Complete startup timing and generate report
if command -v complete_startup_timing >/dev/null 2>&1; then
    end_timing "entrypoint_total" "Complete entrypoint configuration loading"
    complete_startup_timing
fi

# Debug mode: Show comprehensive module loading report
if [ "${DEBUG_MODULE_LOADING:-0}" = "1" ]; then
    echo "=== Module Loading Debug Report ===" >&2
    if command -v get_sourcing_registry >/dev/null 2>&1; then
        echo "=== Sourced Modules Registry ===" >&2
        get_sourcing_registry >&2
    fi
fi

# Export key functions for interactive use
if [ -n "${BASH_VERSION:-}" ]; then
    export -f enhanced_safe_source 2>/dev/null || true
fi

# Mark as loaded (shell-local) for compliance and test detection
DOTFILES_ENTRYPOINT_RC_LOADED=1
DOTFILES_ENTRYPOINT_RC_PID=$$
