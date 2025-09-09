#!/usr/bin/env sh
# shellcheck shell=sh
#{{- includeTemplate "dot_config/ai/snippets/shell/sourceable.sh.tmpl" (dict "path" .path "name" .name) -}}


# =====================================================================

#!/usr/bin/env bash
# =====================================================================
# Optimized Shell Entry Point RC
# Managed by chezmoi | https://github.com/levonk/dotfiles
# Purpose:
#   - High-performance entry point with caching, lazy loading, and performance tracking
#   - Delegates to existing sharedrc.sh for miscellaneous settings and compatibility
#   - Provides modern optimization while maintaining backward compatibility
# Shell Support:
#   - Safe for POSIX shells (Bash, Zsh, Dash, etc.)
#   - Performance optimizations work best with Bash/Zsh
# Security: No sensitive data, no unsafe calls
# Compliance: See LICENSE and admin/licenses.md
# =====================================================================

# Ensure XDG_CONFIG_HOME defaults to ~/.config if not set
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"

# Apply DRY principle with variables for repeated paths
SHELLS_BASE_DIR="${XDG_CONFIG_HOME}/shells"
SHELLS_SHARED_DIR="${SHELLS_BASE_DIR}/shared"
ENV_DIR="$SHELLS_SHARED_DIR/env"
UTIL_DIR="$SHELLS_SHARED_DIR/util"
ALIASES_DIR="$SHELLS_SHARED_DIR/aliases"
SHAREDRC_PATH="$SHELLS_SHARED_DIR/sharedrc.sh"

# Detect current shell for shell-specific configurations
CURRENT_SHELL=""
if [ -n "${ZSH_VERSION:-}" ]; then
    CURRENT_SHELL="zsh"
elif [ -n "${BASH_VERSION:-}" ]; then
    CURRENT_SHELL="bash"
else
    # Try to detect from $0 or $SHELL
    case "${0##*/}" in
        bash|*bash) CURRENT_SHELL="bash" ;;
        zsh|*zsh) CURRENT_SHELL="zsh" ;;
        *)
            case "${SHELL##*/}" in
                bash) CURRENT_SHELL="bash" ;;
                zsh) CURRENT_SHELL="zsh" ;;
                *) CURRENT_SHELL="unknown" ;;
            esac
            ;;
    esac
fi

# Guardrails: ensure no pre-set grep alias interferes during startup
case $- in
  *i*)
    if alias grep >/dev/null 2>&1; then
        unalias grep 2>/dev/null || true
    fi
    ;;
  *) ;;
esac

# Load platform detection utility for cross-platform compatibility
PLATFORM_DETECTION_PATH="$UTIL_DIR/platform-detection.sh"
if [ -r "$PLATFORM_DETECTION_PATH" ] && [ -f "$PLATFORM_DETECTION_PATH" ]; then
    . "$PLATFORM_DETECTION_PATH" || {
        echo "Warning: Failed to source platform detection utility" >&2
    }
else
    echo "Warning: Platform detection utility not found at $PLATFORM_DETECTION_PATH" >&2
fi

# Normalize TTY settings to avoid background-write freezes (SIGTTOU)
# If a terminal has 'tostop' enabled, any background process writing to the TTY
# will be stopped by SIGTTOU, which looks like a freeze during startup if prompts/plugins
# touch the TTY. Disable 'tostop' for interactive shells by default. Opt-out with
# DOTFILES_TTY_TOSTOP=1 to keep 'tostop' enabled.
case $- in
  *i*)
    if [ "${DOTFILES_TTY_TOSTOP:-0}" != "1" ] && [ -t 1 ] && command -v stty >/dev/null 2>&1; then
        # Only change if currently enabled
        if stty -a 2>/dev/null | grep -qw "tostop"; then
            stty -tostop 2>/dev/null || true
        fi
    fi
    ;;
  *) ;;
esac

# Shell-specific directories
if [ "$CURRENT_SHELL" != "unknown" ] && [ "$CURRENT_SHELL" != "" ]; then
    SHELL_SPECIFIC_DIR="$SHELLS_BASE_DIR/$CURRENT_SHELL"
    SHELL_ENV_DIR="$SHELL_SPECIFIC_DIR/env"
    SHELL_UTIL_DIR="$SHELL_SPECIFIC_DIR/util"
    SHELL_ALIASES_DIR="$SHELL_SPECIFIC_DIR/aliases"
    SHELL_COMPLETIONS_DIR="$SHELL_SPECIFIC_DIR/completions"
    SHELL_PROMPTS_DIR="$SHELL_SPECIFIC_DIR/prompts"
else
    SHELL_SPECIFIC_DIR=""
    SHELL_ENV_DIR=""
    SHELL_UTIL_DIR=""
    SHELL_ALIASES_DIR=""
    SHELL_COMPLETIONS_DIR=""
    SHELL_PROMPTS_DIR=""
fi

# Performance optimization settings
export DOTFILES_PERFORMANCE_ENABLED="${DOTFILES_PERFORMANCE_ENABLED:-0}"
export DOTFILES_CACHE_ENABLED="${DOTFILES_CACHE_ENABLED:-1}"
export DEBUG_SOURCING="${DEBUG_SOURCING:-}"

# Debug-only: if the loaded flag is present in the environment, warn (we'll rely on PID guard)
if [ -n "${DEBUG_SOURCING:-}" ] && env | grep -q '^DOTFILES_ENTRYPOINT_RC_LOADED=' 2>/dev/null; then
    echo "Debug: Inherited DOTFILES_ENTRYPOINT_RC_LOADED from parent env; applying PID guard" >&2
fi

# Prevent double-loading only within the same process (PID guard)
if [ -n "${DOTFILES_ENTRYPOINT_RC_PID:-}" ] && [ "${DOTFILES_ENTRYPOINT_RC_PID}" = "$$" ]; then
    [ -n "${DEBUG_SOURCING:-}" ] && echo "Debug: entrypointrc.sh already loaded in this PID ($$), skipping" >&2 || true
    return 0 2>/dev/null || exit 0
fi

# Define dummy timing functions in case performance-timing.sh isn't loaded
if ! command -v start_timing >/dev/null 2>&1; then
    start_timing() { :; }
fi
if ! command -v end_timing >/dev/null 2>&1; then
    end_timing() { :; }
fi

# Initialize performance tracking if enabled
if [ -r "$UTIL_DIR/performance-timing.sh" ]; then
    . "$UTIL_DIR/performance-timing.sh"
    init_performance_tracking
    start_timing "entrypoint_total"
fi

# Load core performance utilities first
start_timing "core_utilities"

# Load sourcing registry for redundancy protection
if [ -r "$UTIL_DIR/sourcing-registry.sh" ]; then
    . "$UTIL_DIR/sourcing-registry.sh"
fi

# Load file caching utility
if [ -r "$UTIL_DIR/file-cache.sh" ]; then
    . "$UTIL_DIR/file-cache.sh"
fi

# Load lazy loading utility
if [ -r "$UTIL_DIR/lazy-loader.sh" ]; then
    . "$UTIL_DIR/lazy-loader.sh"
fi

end_timing "core_utilities" "Core performance utilities"

# Enhanced safe sourcing function that combines all optimizations
enhanced_safe_source() {
    local file_path="$1"
    local description="${2:-$(basename "$file_path" 2>/dev/null || echo "$file_path")}"

    # Debug tracing: Log module loading attempt
    if [ -n "${DEBUG_MODULE_LOADING:-}" ]; then
        echo "[DEBUG] Attempting to load module: $description ($file_path)" >&2
    fi

    # Check if already sourced (redundancy protection)
    if command -v is_already_sourced >/dev/null 2>&1 && is_already_sourced "$file_path"; then
        if [ -n "${DEBUG_MODULE_LOADING:-}" ]; then
            echo "[DEBUG] Module already loaded, skipping: $description" >&2
        fi
        return 0
    fi

    # Debug tracing: Start timing for this module
    local start_time
    if [ -n "${DEBUG_MODULE_LOADING:-}" ] && command -v get_current_time >/dev/null 2>&1; then
        start_time=$(get_current_time)
    fi

    # Use cached sourcing if available
    local result=0
    if command -v cached_source >/dev/null 2>&1; then
        cached_source "$file_path" "$description" || result=$?
    elif command -v safe_source >/dev/null 2>&1; then
        safe_source "$file_path" "$description" || result=$?
    else
        # Fallback to basic sourcing with validation
        if [ -r "$file_path" ]; then
            . "$file_path" || result=$?
        else
            echo "Warning: Could not source $description - file not readable: $file_path" >&2
            result=1
        fi
    fi

    # Debug tracing: Log completion and timing
    if [ -n "${DEBUG_MODULE_LOADING:-}" ]; then
        if [ $result -eq 0 ]; then
            if [ -n "$start_time" ] && command -v get_current_time >/dev/null 2>&1; then
                local end_time
                end_time=$(get_current_time)
                local duration=$((end_time - start_time))
                echo "[DEBUG] Successfully loaded module: $description (${duration}ms)" >&2
            else
                echo "[DEBUG] Successfully loaded module: $description" >&2
            fi
        else
            echo "[DEBUG] Failed to load module: $description (exit code: $result)" >&2
        fi
    fi

    return $result
}

# Load essential environment variables first (XDG compliance)
start_timing "xdg_environment"

# XDG environment variables (single source of truth)
XDG_DIRS_ENV="$ENV_DIR/__xdg-env.sh"
if [ -r "$XDG_DIRS_ENV" ]; then
    enhanced_safe_source "$XDG_DIRS_ENV" "XDG environment variables"
else
    echo "Warning: Could not source XDG environment variables from $XDG_DIRS_ENV" >&2
fi

end_timing "xdg_environment" "XDG environment setup"

# Register lazy-loaded modules for optional functionality
start_timing "lazy_registration"

if command -v register_lazy_module >/dev/null 2>&1; then
    # Register SHARED aliases for lazy loading (loaded when first alias is used)
    if [ -d "$ALIASES_DIR" ]; then
        find "$ALIASES_DIR" -maxdepth 1 -type f -name "*.sh" 2>/dev/null | while IFS= read -r alias_file; do
            if [ -r "$alias_file" ]; then
                module_name="shared_aliases_$(basename "$alias_file" .sh)"
                # Extract commonly used commands from alias files for triggers
                case "$(basename "$alias_file" .sh)" in
                    modern-tools)
                        triggers="ll,la"
                        ;;
                    git-aliases)
                        triggers="g,gst,gco,gaa,gcm"
                        ;;
                    *)
                        triggers=""  # No default core command wrapping
                        ;;
                esac
                register_lazy_module "$module_name" "$alias_file" "$triggers"
            fi
        done
    fi

    # Register SHARED utility modules for lazy loading (except core performance utilities)
    if [ -d "$UTIL_DIR" ]; then
        find "$UTIL_DIR" -maxdepth 1 -type f -name "*.sh" 2>/dev/null | while IFS= read -r util_file; do
            if [ -r "$util_file" ]; then
                util_name="$(basename "$util_file" .sh)"
                # Skip core utilities that are already loaded
                case "$util_name" in
                    sourcing-registry|file-cache|lazy-loader|performance-timing)
                        continue
                        ;;
                    *)
                        register_lazy_module "shared_util_$util_name" "$util_file" ""
                        ;;
                esac
            fi
        done
    fi

    # Register SHELL-SPECIFIC configurations for lazy loading
    if [ -n "$SHELL_SPECIFIC_DIR" ] && [ -d "$SHELL_SPECIFIC_DIR" ]; then
        # Register shell-specific aliases
        if [ -d "$SHELL_ALIASES_DIR" ]; then
            if [ "$CURRENT_SHELL" = "zsh" ]; then
                find "$SHELL_ALIASES_DIR" -maxdepth 1 -type f \( -name "*.zsh" -o -name "*.sh" \) 2>/dev/null | while IFS= read -r alias_file; do
                    if [ -r "$alias_file" ]; then
                        module_name="${CURRENT_SHELL}_aliases_$(basename "$alias_file" .zsh)"
                        module_name="${module_name%.sh}"
                        # Shell-specific triggers based on file name
                        case "$(basename "$alias_file" .zsh)" in
                            completion*)
                                triggers=""  # No triggers for completion aliases
                                ;;
                            prompt*)
                                triggers=""  # No triggers for prompt aliases
                                ;;
                            *)
                                triggers=""  # Avoid wrapping core commands by default
                                ;;
                        esac
                        register_lazy_module "$module_name" "$alias_file" "$triggers"
                    fi
                done
            else
                find "$SHELL_ALIASES_DIR" -maxdepth 1 -type f \( -name "*.bash" -o -name "*.sh" \) 2>/dev/null | while IFS= read -r alias_file; do
                    if [ -r "$alias_file" ]; then
                        module_name="${CURRENT_SHELL}_aliases_$(basename "$alias_file" .bash)"
                        module_name="${module_name%.sh}"
                        # Shell-specific triggers based on file name
                        case "$(basename "$alias_file" .bash)" in
                            completion*)
                                triggers=""  # No triggers for completion aliases
                                ;;
                            prompt*)
                                triggers=""  # No triggers for prompt aliases
                                ;;
                            *)
                                triggers=""  # Avoid wrapping core commands by default
                                ;;
                        esac
                        register_lazy_module "$module_name" "$alias_file" "$triggers"
                    fi
                done
            fi
        fi

        # Register shell-specific utilities
        if [ -d "$SHELL_UTIL_DIR" ]; then
            if [ "$CURRENT_SHELL" = "zsh" ]; then
                find "$SHELL_UTIL_DIR" -maxdepth 1 -type f \( -name "*.zsh" -o -name "*.sh" \) 2>/dev/null | while IFS= read -r util_file; do
                    if [ -r "$util_file" ]; then
                        util_base="$(basename "$util_file")"
                        case "$util_base" in
                            *.zsh) util_name="$(basename "$util_file" .zsh)" ;;
                            *.sh)  util_name="$(basename "$util_file" .sh)"  ;;
                            *)      util_name="$util_base" ;;
                        esac
                        register_lazy_module "${CURRENT_SHELL}_util_$util_name" "$util_file" ""
                    fi
                done
            else
                find "$SHELL_UTIL_DIR" -maxdepth 1 -type f \( -name "*.bash" -o -name "*.sh" \) 2>/dev/null | while IFS= read -r util_file; do
                    if [ -r "$util_file" ]; then
                        util_name="$(basename "$util_file")"
                        util_name="${util_name%.bash}"
                        util_name="${util_name%.sh}"
                        register_lazy_module "${CURRENT_SHELL}_util_$util_name" "$util_file" ""
                    fi
                done
            fi
        fi

        # Register shell-specific completions (typically loaded on-demand)
        if [ -d "$SHELL_COMPLETIONS_DIR" ]; then
            if [ "$CURRENT_SHELL" = "zsh" ]; then
                find "$SHELL_COMPLETIONS_DIR" -maxdepth 1 -type f \( -name "*.zsh" -o -name "*.sh" \) 2>/dev/null | while IFS= read -r completion_file; do
                    if [ -r "$completion_file" ]; then
                        completion_name="$(basename "$completion_file")"
                        completion_name="${completion_name%.zsh}"
                        completion_name="${completion_name%.sh}"
                        register_lazy_module "${CURRENT_SHELL}_completion_$completion_name" "$completion_file" ""
                    fi
                done
            else
                find "$SHELL_COMPLETIONS_DIR" -maxdepth 1 -type f \( -name "*.bash" -o -name "*.sh" \) 2>/dev/null | while IFS= read -r completion_file; do
                    if [ -r "$completion_file" ]; then
                        completion_name="$(basename "$completion_file")"
                        completion_name="${completion_name%.bash}"
                        completion_name="${completion_name%.sh}"
                        register_lazy_module "${CURRENT_SHELL}_completion_$completion_name" "$completion_file" ""
                    fi
                done
            fi
        fi

        # Eagerly source Zsh plugin manager and prompt to ensure prompt is set early
        if [ "$CURRENT_SHELL" = "zsh" ]; then
            if [ -n "${DEBUG_PROMPT:-}" ]; then
                echo "[entry] CURRENT_SHELL=zsh" >&2
                echo "[entry] ZSH UTIL DIR: $SHELL_UTIL_DIR" >&2
                echo "[entry] ZSH PROMPT DIR: $SHELL_PROMPTS_DIR" >&2
            fi
            if [ -r "$SHELL_UTIL_DIR/om-my-zsh-plugins.zsh" ]; then
                [ -n "${DEBUG_PROMPT:-}" ] && echo "[entry] sourcing OMZ: $SHELL_UTIL_DIR/om-my-zsh-plugins.zsh" >&2 || true
                enhanced_safe_source "$SHELL_UTIL_DIR/om-my-zsh-plugins.zsh" "Zsh oh-my-zsh plugins"
            else
                [ -n "${DEBUG_PROMPT:-}" ] && echo "[entry] OMZ not readable: $SHELL_UTIL_DIR/om-my-zsh-plugins.zsh" >&2 || true
            fi
            if [ -r "$SHELL_PROMPTS_DIR/p10k.zsh" ]; then
                [ -n "${DEBUG_PROMPT:-}" ] && echo "[entry] sourcing prompt: $SHELL_PROMPTS_DIR/p10k.zsh" >&2 || true
                enhanced_safe_source "$SHELL_PROMPTS_DIR/p10k.zsh" "Zsh prompt (Powerlevel10k/starship/fallback)"
                export DOTFILES_PROMPT_SOURCED=1
            elif [ -r "$SHELL_PROMPTS_DIR/prompt.zsh" ]; then
                [ -n "${DEBUG_PROMPT:-}" ] && echo "[entry] sourcing prompt(legacy): $SHELL_PROMPTS_DIR/prompt.zsh" >&2 || true
                enhanced_safe_source "$SHELL_PROMPTS_DIR/prompt.zsh" "Zsh prompt (legacy dispatcher)"
                export DOTFILES_PROMPT_SOURCED=1
            else
                [ -n "${DEBUG_PROMPT:-}" ] && echo "[entry] no prompt file readable (tried p10k.zsh, prompt.zsh) in $SHELL_PROMPTS_DIR" >&2 || true
            fi
        fi

        # Register shell-specific prompts (loaded when prompt is changed)
        if [ -d "$SHELL_PROMPTS_DIR" ]; then
            find "$SHELL_PROMPTS_DIR" -maxdepth 1 -type f \( -name "*.zsh" -o -name "*.sh" \) 2>/dev/null | while IFS= read -r prompt_file; do
                if [ -r "$prompt_file" ]; then
                    prompt_name="$(basename "$prompt_file")"
                    register_lazy_module "${CURRENT_SHELL}_prompt_$prompt_name" "$prompt_file" ""
                fi
            done
        fi
    fi
fi

end_timing "lazy_registration" "Lazy module registration"

# Load essential modules immediately (preload critical functionality)
start_timing "essential_preload"

# Define essential modules that should be loaded immediately
DOTFILES_ESSENTIAL_MODULES="${DOTFILES_ESSENTIAL_MODULES:-shared_aliases_modern-tools}"

if command -v preload_essential_modules >/dev/null 2>&1; then
    preload_essential_modules
else
    # Fallback: load essential shared aliases directly
    if [ -r "$ALIASES_DIR/modern-tools.sh" ]; then
        enhanced_safe_source "$ALIASES_DIR/modern-tools.sh" "Modern tools aliases (shared)"
    fi
fi

# Load essential shell-specific environment variables immediately
if [ -n "$SHELL_ENV_DIR" ] && [ -d "$SHELL_ENV_DIR" ]; then
    if [ "$CURRENT_SHELL" = "zsh" ]; then
        find "$SHELL_ENV_DIR" -maxdepth 1 -type f \( -name "*.zsh" -o -name "*.sh" \) 2>/dev/null | while IFS= read -r env_file; do
            if [ -r "$env_file" ]; then
                enhanced_safe_source "$env_file" "${CURRENT_SHELL} environment: $(basename "$env_file")"
            fi
        done
    elif [ "$CURRENT_SHELL" = "bash" ]; then
        find "$SHELL_ENV_DIR" -maxdepth 1 -type f \( -name "*.bash" -o -name "*.sh" \) 2>/dev/null | while IFS= read -r env_file; do
            if [ -r "$env_file" ]; then
                enhanced_safe_source "$env_file" "${CURRENT_SHELL} environment: $(basename "$env_file")"
            fi
        done
    else
        find "$SHELL_ENV_DIR" -maxdepth 1 -type f -name "*.sh" 2>/dev/null | while IFS= read -r env_file; do
            if [ -r "$env_file" ]; then
                enhanced_safe_source "$env_file" "${CURRENT_SHELL} environment: $(basename "$env_file")"
            fi
        done
    fi
fi

end_timing "essential_preload" "Essential modules preload"

# Delegate to existing sharedrc.sh for miscellaneous settings and compatibility
start_timing "sharedrc_delegation"

if [ -r "$SHAREDRC_PATH" ]; then
    # Use enhanced sourcing for the main sharedrc
    enhanced_safe_source "$SHAREDRC_PATH" "Shared RC (miscellaneous settings)"

    if [ -n "${DEBUG_SOURCING:-}" ]; then
        echo "Debug: Successfully delegated to sharedrc.sh" >&2
    fi
else
    echo "Warning: Could not find sharedrc.sh at $SHAREDRC_PATH" >&2

    # Fallback: load remaining configurations manually
    echo "Info: Falling back to manual configuration loading" >&2

    # Load remaining SHARED environment files (excluding XDG which was already loaded)
    if [ -d "$ENV_DIR" ]; then
        find "$ENV_DIR" -maxdepth 1 -type f -name "*.sh" 2>/dev/null | while IFS= read -r env_file; do
            if [ -r "$env_file" ] && [ "$(basename "$env_file")" != "__xdg-env.sh" ]; then
                case "$(basename "$env_file")" in
                    *.sh)
                        enhanced_safe_source "$env_file" "Shared environment: $(basename "$env_file")"
                        ;;
                esac
            fi
        done
    fi

    # Load remaining SHARED utility files (excluding performance utilities)
    if [ -d "$UTIL_DIR" ]; then
        find "$UTIL_DIR" -maxdepth 1 -type f -name "*.sh" 2>/dev/null | while IFS= read -r util_file; do
            if [ -r "$util_file" ]; then
                util_name="$(basename "$util_file" .sh)"
                case "$util_name" in
                    sourcing-registry|file-cache|lazy-loader|performance-timing)
                        continue  # Already loaded
                        ;;
                    *)
                        if head -1 "$util_file" | grep -q '^#!/.*sh' 2>/dev/null; then
                            enhanced_safe_source "$util_file" "Shared utility: $util_name"
                        fi
                        ;;
                esac
            fi
        done
    fi

    # Load remaining SHARED aliases (not registered for lazy loading)
    if [ -d "$ALIASES_DIR" ]; then
        find "$ALIASES_DIR" -maxdepth 1 -type f -name "*.sh" 2>/dev/null | while IFS= read -r alias_file; do
            if [ -r "$alias_file" ] && [ "$(basename "$alias_file")" != "modern-tools.sh" ]; then
                case "$(basename "$alias_file")" in
                    *.sh)
                        enhanced_safe_source "$alias_file" "Shared aliases: $(basename "$alias_file")"
                        ;;
                esac
            fi
        done
    fi

    # Load SHELL-SPECIFIC configurations (fallback mode)
    if [ -n "$SHELL_SPECIFIC_DIR" ] && [ -d "$SHELL_SPECIFIC_DIR" ]; then
        echo "Info: Loading ${CURRENT_SHELL}-specific configurations" >&2

        # Shell-specific environment files (already loaded in essential preload, but check for missed ones)
        if [ -d "$SHELL_ENV_DIR" ]; then
            find "$SHELL_ENV_DIR" -maxdepth 1 -type f -name "*.sh" 2>/dev/null | while IFS= read -r env_file; do
                if [ -r "$env_file" ]; then
                    # Skip if already loaded by is_already_sourced check
                    enhanced_safe_source "$env_file" "${CURRENT_SHELL} environment: $(basename "$env_file")"
                fi
            done
        fi

        # Shell-specific utilities (load immediately in fallback mode)
        if [ -d "$SHELL_UTIL_DIR" ]; then
            if [ "$CURRENT_SHELL" = "zsh" ]; then
                find "$SHELL_UTIL_DIR" -maxdepth 1 -type f \( -name "*.zsh" -o -name "*.sh" \) 2>/dev/null | while IFS= read -r util_file; do
                    if [ -r "$util_file" ]; then
                        enhanced_safe_source "$util_file" "${CURRENT_SHELL} utility: $(basename "$util_file")"
                    fi
                done
            else
                find "$SHELL_UTIL_DIR" -maxdepth 1 -type f \(-name "*.sh" -o -name "*.bash"\) 2>/dev/null | while IFS= read -r util_file; do
                    if [ -r "$util_file" ]; then
                        if head -1 "$util_file" | grep -q '^#!/.*sh' 2>/dev/null; then
                            enhanced_safe_source "$util_file" "${CURRENT_SHELL} utility: $(basename "$util_file" .sh)"
                        fi
                    fi
                done
            fi
        fi

        # Shell-specific aliases (load immediately in fallback mode)
        if [ -d "$SHELL_ALIASES_DIR" ]; then
            if [ "$CURRENT_SHELL" = "zsh" ]; then
                find "$SHELL_ALIASES_DIR" -maxdepth 1 -type f \( -name "*.zsh" -o -name "*.sh" \) 2>/dev/null | while IFS= read -r alias_file; do
                    if [ -r "$alias_file" ]; then
                        enhanced_safe_source "$alias_file" "${CURRENT_SHELL} aliases: $(basename "$alias_file")"
                    fi
                done
            else
                find "$SHELL_ALIASES_DIR" -maxdepth 1 -type f \( -name "*.bash" -o -name "*.sh" \) 2>/dev/null | while IFS= read -r alias_file; do
                    if [ -r "$alias_file" ]; then
                        enhanced_safe_source "$alias_file" "${CURRENT_SHELL} aliases: $(basename "$alias_file")"
                    fi
                done
            fi
        fi
    fi
fi

end_timing "sharedrc_delegation" "Shared RC delegation"

# Performance cleanup and reporting
start_timing "cleanup_and_reporting"

# Clean old cache files periodically (every 10th shell startup)
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
if [ -n "${DEBUG_MODULE_LOADING:-}" ]; then
    echo "=== Module Loading Debug Report ===" >&2
    echo "Debug: Module loading tracing was enabled" >&2
    if command -v get_sourcing_registry >/dev/null 2>&1; then
        echo "=== Sourced Modules Registry ===" >&2
        get_sourcing_registry >&2
    fi
fi

# Optional: Show performance stats if debug mode is enabled
if [ -n "${DEBUG_SOURCING:-}" ] && command -v get_performance_stats >/dev/null 2>&1; then
    echo "=== Entrypoint Performance Report ===" >&2
    get_performance_stats >&2
    echo "=== Lazy Loading Status ===" >&2
    get_lazy_stats >&2
fi

# Export key functions for interactive use
if [ -n "${BASH_VERSION:-}" ]; then
    # Export performance and utility functions for interactive shells
    export -f enhanced_safe_source 2>/dev/null || true
fi

# Mark as loaded (shell-local) for compliance and test detection
# Do NOT export: exporting causes child shells to skip initialization
DOTFILES_ENTRYPOINT_RC_LOADED=1
DOTFILES_ENTRYPOINT_RC_PID=$$

# Success indicator
if [ -n "${DEBUG_SOURCING:-}" ]; then
    echo "Debug: Optimized entrypoint configuration loaded successfully" >&2
    echo "Debug: Use 'dotfiles-perf' to view performance statistics" >&2
fi

if [ -n "${DEBUG_MODULE_LOADING:-}" ]; then
    echo "Debug: Module loading tracing completed" >&2
    echo "Debug: Set DEBUG_MODULE_LOADING=1 to enable detailed module loading traces" >&2
    echo "Debug: Available debug commands: dotfiles-perf, dotfiles-lazy, dotfiles-debug" >&2
fi
