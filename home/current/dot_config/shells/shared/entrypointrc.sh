#!/usr/bin/env sh
# shellcheck shell=sh
#{{- includeTemplate "dot_config/ai/templates/shell/sourceable.sh.tmpl" (dict "path" .path "name" .name) -}}

# =====================================================================
# Optimized Shell Entry Point RC

set +e;
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

dotfiles_record_startup_token() {
    local _token="$1"

    [ -n "$_token" ] || return 0

    case ":${STARTUP_TEST_ENV:-}:" in
        *:"$_token":*)
            return 0
            ;;
    esac

    if [ -n "${STARTUP_TEST_ENV:-}" ]; then
        STARTUP_TEST_ENV="$_token:${STARTUP_TEST_ENV}"
    else
        STARTUP_TEST_ENV="$_token"
    fi

    export STARTUP_TEST_ENV
}

dotfiles_relative_token() {
    local _dir="$1"
    local _token="$_dir"

    case "$_dir" in
        "")
            printf '%s\n' ""
            return 0
            ;;
    esac

    if [ -n "${SHELLS_BASE_DIR:-}" ]; then
        case "$_dir" in
            "$SHELLS_BASE_DIR"/*)
                _token="${_dir#"$SHELLS_BASE_DIR"/}"
                ;;
        esac
    fi

    case "$_token" in
        ""|"$SHELLS_BASE_DIR")
            printf '%s\n' ""
            ;;
        *)
            printf '%s\n' "$_token"
            ;;
    esac
}

dotfiles_record_startup_dir() {
    local _dir="$1"

    [ -n "$_dir" ] || return 0

    local _token
    _token="$(dotfiles_relative_token "$_dir")"
    [ -n "$_token" ] || return 0

    dotfiles_record_startup_token "$_token"
}

dotfiles_record_startup_dir "$ENV_DIR"
dotfiles_record_startup_dir "$UTIL_DIR"
dotfiles_record_startup_dir "$ALIASES_DIR"
dotfiles_record_startup_dir "$SHELLS_SHARED_DIR/prompts"

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
    SHELL_PLUGINS_DIR="$SHELL_SPECIFIC_DIR/plugins"
else
    SHELL_SPECIFIC_DIR=""
    SHELL_ENV_DIR=""
    SHELL_UTIL_DIR=""
    SHELL_ALIASES_DIR=""
    SHELL_COMPLETIONS_DIR=""
    SHELL_PROMPTS_DIR=""
    SHELL_PLUGINS_DIR=""
fi

dotfiles_record_startup_dir "$SHELL_ENV_DIR"
dotfiles_record_startup_dir "$SHELL_UTIL_DIR"
dotfiles_record_startup_dir "$SHELL_ALIASES_DIR"
dotfiles_record_startup_dir "$SHELL_COMPLETIONS_DIR"
dotfiles_record_startup_dir "$SHELL_PROMPTS_DIR"
dotfiles_record_startup_dir "$SHELL_PLUGINS_DIR"

# Performance optimization settings
export DOTFILES_PERFORMANCE_ENABLED="${DOTFILES_PERFORMANCE_ENABLED:-0}"
export DOTFILES_CACHE_ENABLED="${DOTFILES_CACHE_ENABLED:-1}"
export DEBUG_SOURCING="${DEBUG_SOURCING:-}"
export DEBUG_MODULE_LOADING="${DEBUG_MODULE_LOADING:-0}"

module_debug_enabled() {
    case "${DEBUG_MODULE_LOAD:-${DEBUG_MODULE_LOADING:-0}}" in
        1|true|TRUE|True|on|ON|On) return 0 ;;
        *) return 1 ;;
    esac
}

module_debug_label() {
    local _mdl_path="$1"
    local _mdl_trimmed="$_mdl_path"

    if [ -n "${XDG_CONFIG_HOME:-}" ]; then
        case "$_mdl_path" in
            "$XDG_CONFIG_HOME"/*)
                _mdl_trimmed="${_mdl_path#"$XDG_CONFIG_HOME"/}"
                ;;
        esac
    fi

    case "$_mdl_trimmed" in
        "$HOME"/*)
            _mdl_trimmed="${_mdl_trimmed#"$HOME"/}"
            ;;
    esac

    printf '%s\n' "$_mdl_trimmed"
}

module_debug_enter() {
    module_debug_enabled || return 0
    printf '####### [ENTERING] %s\n' "$(module_debug_label "$1")" >&2
}

module_debug_exit() {
    module_debug_enabled || return 0
    printf '##### [EXITING] %s\n' "$(module_debug_label "$1")" >&2
}

strip_shell_extension() {
    local _name="$1"
    _name="${_name%.zsh}"
    _name="${_name%.bash}"
    _name="${_name%.sh}"
    _name="${_name%.env}"
    printf '%s\n' "$_name"
}

for_each_shell_file() {
    dir="$1"
    extensions="$2"
    sort_mode="${3:-0}"

    if [ ! -d "$dir" ]; then
        return 0
    fi

    list_file=$(mktemp)
    result_file=$(mktemp)

    find "$dir" -maxdepth 1 -type f > "$list_file"

    while IFS= read -r file; do
        [ -n "$file" ] || continue
        for ext in $extensions; do
            ext="${ext#.}"
            [ -n "$ext" ] || continue
            case "$file" in
                *."$ext")
                    printf '%s\n' "$file" >> "$result_file"
                    break
                    ;;
            esac
        done
    done < "$list_file"

    if [ -s "$result_file" ]; then
        if [ "$sort_mode" = "1" ]; then
            sort "$result_file"
        else
            cat "$result_file"
        fi
    fi

    rm -f "$list_file" "$result_file"
}

# Debug-only: if the loaded flag is present in the environment, warn (we'll rely on PID guard)
if [ -n "${DEBUG_SOURCING:-}" ] && env | grep -q '^DOTFILES_ENTRYPOINT_RC_LOADED=' 2>/dev/null; then
    echo "Debug: Inherited DOTFILES_ENTRYPOINT_RC_LOADED from parent env; applying PID guard" >&2
{{ ... }}
fi

# Prevent double-loading only within the same process (PID guard)
if [ -n "${DOTFILES_ENTRYPOINT_RC_PID:-}" ] && [ "${DOTFILES_ENTRYPOINT_RC_PID}" = "$$" ]; then
    [ -n "${DEBUG_SOURCING:-}" ] && echo "Debug: entrypointrc.sh already loaded in this PID ($$), skipping" >&2
    case "$- in *i*)" in
        *i*) return 0 ;; # Interactive shell, return
        *) exit 0 ;;   # Non-interactive, exit
    esac
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
    local start_time=""
    local end_time=""
    local duration=""

    # Debug tracing: Log module loading attempt
    if [ "${DEBUG_MODULE_LOADING:-0}" = "1" ]; then
        echo "[DEBUG] Attempting to load module: $description ($file_path)" >&2
    fi

    # Check if already sourced (redundancy protection)
    if command -v is_already_sourced >/dev/null 2>&1 && is_already_sourced "$file_path"; then
        if [ "${DEBUG_MODULE_LOADING:-0}" = "1" ]; then
            echo "[DEBUG] Module already loaded, skipping: $description" >&2
        fi
        return 0
    fi

    # Debug tracing: Start timing for this module
    if [ "${DEBUG_MODULE_LOADING:-0}" = "1" ] && command -v get_current_time >/dev/null 2>&1; then
        start_time="$(get_current_time 2>/dev/null || true)"
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
    if [ "${DEBUG_MODULE_LOADING:-0}" = "1" ]; then
        if [ $result -eq 0 ]; then
            if [ -n "${start_time:-}" ] && command -v get_current_time >/dev/null 2>&1; then
                end_time="$(get_current_time 2>/dev/null || true)"
                if [ -n "${end_time:-}" ]; then
                    duration=$((end_time - start_time))
                    echo "[DEBUG] Successfully loaded module: $description (${duration}ms)" >&2
                else
                    echo "[DEBUG] Successfully loaded module: $description" >&2
                fi
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

# Helper function to source all valid shell scripts in a directory.
# Usage: _source_modules_from_dir <directory> <description_prefix> <shell_extensions> <sort_mode> [exclude_pattern]
_source_modules_from_dir() {
    local dir_path="$1"
    local desc_prefix="$2"
    local shell_exts="$3"
    local sort_mode="0"
    local exclude_pattern=""
    local file_path
    local file_basename

    if [ $# -ge 4 ]; then
        sort_mode="$4"
    fi
    if [ $# -ge 5 ]; then
        exclude_pattern="$5"
    fi

    if [ ! -d "$dir_path" ]; then
        return
    fi

    module_debug_enter "$dir_path"

    local list_tmp
    list_tmp="$(mktemp)"
    for_each_shell_file "$dir_path" "$shell_exts" "$sort_mode" >"$list_tmp"

    while IFS= read -r file_path; do
        if [ -r "$file_path" ]; then
            file_basename="$(basename "$file_path")"
            if [ -n "$exclude_pattern" ] && printf '%s\n' "$file_basename" | grep -qE -- "$exclude_pattern"; then
                continue
            fi
            enhanced_safe_source "$file_path" "${desc_prefix}: $(strip_shell_extension "$file_basename")"
        fi
    done <"$list_tmp"

    rm -f "$list_tmp"

    module_debug_exit "$dir_path"
}

# Helper function to register all valid shell scripts in a directory for lazy loading.
# Usage: _register_lazy_modules_from_dir <directory> <module_prefix> <shell_extensions>
_register_lazy_modules_from_dir() {
    local dir_path="$1"
    local module_prefix="$2"
    local shell_exts="$3"
    local file_path
    local file_basename

    if [ ! -d "$dir_path" ]; then
        return
    fi

    local list_tmp
    list_tmp="$(mktemp)"
    for_each_shell_file "$dir_path" "$shell_exts" >"$list_tmp"

    while IFS= read -r file_path; do
        if [ -r "$file_path" ]; then
            file_basename="$(strip_shell_extension "$(basename "$file_path")")"
            # Skip specific util files that are not lazy-loadable
            case "$file_basename" in
                'lazy-loader'|'ssh-agent'|'performance')
                    continue
                    ;;
                *)
                    register_lazy_module "${module_prefix}_${file_basename}" "$file_path" ""
                    ;;
            esac
        fi
    done <"$list_tmp"

    rm -f "$list_tmp"
}

start_timing "lazy_registration"

if command -v register_lazy_module >/dev/null 2>&1; then
    # Register SHARED aliases for lazy loading (loaded when first alias is used)
    if [ -d "$ALIASES_DIR" ]; then
        alias_list_tmp="$(mktemp)"
        for_each_shell_file "$ALIASES_DIR" "sh bash env" >"$alias_list_tmp"

        while IFS= read -r alias_file; do
            if [ -r "$alias_file" ]; then
                alias_stub="$(strip_shell_extension "$(basename "$alias_file")")"
                module_name="shared_aliases_${alias_stub}"
                # Extract commonly used commands from alias files for triggers
                case "$alias_stub" in
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
        done <"$alias_list_tmp"

        rm -f "$alias_list_tmp"
    fi

    # Register SHARED utility modules for lazy loading (except core performance utilities)
    _register_lazy_modules_from_dir "$UTIL_DIR" "shared_util" "sh bash env"

    # Register SHELL-SPECIFIC configurations for lazy loading
    if [ -n "$SHELL_SPECIFIC_DIR" ] && [ -d "$SHELL_SPECIFIC_DIR" ]; then
        shell_specific_exts="bash sh env"
        if [ "$CURRENT_SHELL" = "zsh" ]; then
            shell_specific_exts="zsh sh bash env"
        fi

        # Register shell-specific aliases (custom logic for triggers, no helper function)
        if [ -d "$SHELL_ALIASES_DIR" ]; then
            shell_alias_list_tmp="$(mktemp)"
            for_each_shell_file "$SHELL_ALIASES_DIR" "$shell_specific_exts" >"$shell_alias_list_tmp"

            while IFS= read -r alias_file; do
                if [ -r "$alias_file" ]; then
                    alias_stub="$(strip_shell_extension "$(basename "$alias_file")")"
                    module_name="${CURRENT_SHELL}_aliases_${alias_stub}"
                    case "$alias_stub" in
                        completion*|prompt*) triggers="" ;;
                        *) triggers="" ;;
                    esac
                    register_lazy_module "$module_name" "$alias_file" "$triggers"
                fi
            done <"$shell_alias_list_tmp"

            rm -f "$shell_alias_list_tmp"
        fi

        # Register shell-specific utilities, completions, and prompts
        _register_lazy_modules_from_dir "$SHELL_UTIL_DIR" "${CURRENT_SHELL}_util" "$shell_specific_exts"
        _register_lazy_modules_from_dir "$SHELL_COMPLETIONS_DIR" "${CURRENT_SHELL}_completion" "$shell_specific_exts"
        _register_lazy_modules_from_dir "$SHELL_PROMPTS_DIR" "${CURRENT_SHELL}_prompt" "$shell_specific_exts"

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
    shell_env_exts="sh bash env"
    if [ "$CURRENT_SHELL" = "zsh" ]; then
        shell_env_exts="zsh sh bash env"
    fi
    _source_modules_from_dir "$SHELL_ENV_DIR" "${CURRENT_SHELL} environment" "$shell_env_exts" 0
    unset shell_env_exts 2>/dev/null || true
fi

# Proactively load shared environment modules (excluding XDG) only when debug logging is enabled.
if [ "${DEBUG_MODULE_LOADING:-0}" = "1" ] && [ -d "$ENV_DIR" ]; then
    _source_modules_from_dir "$ENV_DIR" "Shared environment (debug)" "sh bash env" 1 "^__xdg-env\\.sh$"
fi

end_timing "essential_preload" "Essential modules preload"

# Delegate to existing sharedrc.sh for backward compatibility
# start_timing "legacy_sharedrc"
# if [ -r "$SHAREDRC_PATH" ]; then
#     # Unset the PID guard before sourcing sharedrc to allow it to run its own logic
#     # (it has its own separate double-sourcing guard)
#     unset DOTFILES_ENTRYPOINT_RC_PID
#     enhanced_safe_source "$SHAREDRC_PATH" "Legacy sharedrc.sh"
#
#     if [ -n "${DEBUG_SOURCING:-}" ]; then
#         echo "Debug: Successfully delegated to sharedrc.sh" >&2
#     fi
# else
#     echo "Warning: Could not find sharedrc.sh at $SHAREDRC_PATH" >&2
#
#     # Fallback: load remaining configurations manually
#     echo "Info: Falling back to manual configuration loading" >&2
#
#     # Load remaining SHARED environment files (excluding XDG which was already loaded)
#     _source_modules_from_dir "$ENV_DIR" "Shared environment" "sh bash env" 1 "^__xdg-env\.sh$"
#
#     # Load remaining SHARED utility files (excluding performance utilities)
#     _source_modules_from_dir "$UTIL_DIR" "Shared utility" "sh bash env" 0 "^(sourcing-registry|file-cache|lazy-loader|performance-timing)\.sh$"
#
#     # Load remaining SHARED aliases (not registered for lazy loading)
#     _source_modules_from_dir "$ALIASES_DIR" "Shared aliases" "sh bash env" 0 "^modern-tools\.sh$"
#
#     # Load SHELL-SPECIFIC configurations (fallback mode)
#     if [ -n "$SHELL_SPECIFIC_DIR" ] && [ -d "$SHELL_SPECIFIC_DIR" ]; then
#         echo "Info: Loading ${CURRENT_SHELL}-specific configurations" >&2
#
#         local shell_exts="bash sh env"
#         if [ "$CURRENT_SHELL" = "zsh" ]; then
#             shell_exts="zsh sh bash env"
#         fi
#
#         _source_modules_from_dir "$SHELL_ENV_DIR" "${CURRENT_SHELL} environment" "$shell_exts" 0
#         _source_modules_from_dir "$SHELL_UTIL_DIR" "${CURRENT_SHELL} utility" "$shell_exts" 0
#         _source_modules_from_dir "$SHELL_ALIASES_DIR" "${CURRENT_SHELL} aliases" "$shell_exts" 0
#     fi
# fi
#
# end_timing "sharedrc_delegation" "Shared RC delegation"

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
if [ "${DEBUG_MODULE_LOADING:-0}" = "1" ]; then
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

if [ "${DEBUG_MODULE_LOADING:-0}" = "1" ]; then
    echo "Debug: Module loading tracing completed" >&2
    echo "Debug: Set DEBUG_MODULE_LOADING=1 to enable detailed module loading traces" >&2
    echo "Debug: Available debug commands: dotfiles-perf, dotfiles-lazy, dotfiles-debug" >&2
fi

set -e
