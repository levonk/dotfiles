#!/usr/bin/env sh
# shellcheck shell=sh

# =============================================================================
# 04-performance-and-lazy-load.sh
#
# ## Purpose
#
# - Initializes performance tracking and loads core performance utilities.
# - Registers shared and shell-specific modules for lazy loading to improve
#   shell startup time.
# =============================================================================

# --- Performance and Core Utility Loading ---

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

if [ -r "$UTIL_DIR/sourcing-registry.sh" ]; then
    . "$UTIL_DIR/sourcing-registry.sh"
fi
if [ -r "$UTIL_DIR/file-cache.sh" ]; then
    . "$UTIL_DIR/file-cache.sh"
fi
if [ -r "$UTIL_DIR/lazy-loader.sh" ]; then
    . "$UTIL_DIR/lazy-loader.sh"
fi

end_timing "core_utilities" "Core performance utilities"

# --- Lazy Module Registration ---

start_timing "lazy_registration"

if command -v register_lazy_module >/dev/null 2>&1; then
    # Register SHARED aliases for lazy loading
    if [ -d "$ALIASES_DIR" ]; then
        alias_list_tmp="$(mktemp)"
        for_each_shell_file "$ALIASES_DIR" "sh bash env" >"$alias_list_tmp"

        while IFS= read -r alias_file; do
            if [ -r "$alias_file" ]; then
                alias_stub="$(strip_shell_extension "$(basename "$alias_file")")"
                module_name="shared_aliases_${alias_stub}"
                case "$alias_stub" in
                    modern-tools) triggers="ll,la" ;;
                    git-aliases) triggers="g,gst,gco,gaa,gcm" ;;
                    *) triggers="" ;;
                esac
                register_lazy_module "$module_name" "$alias_file" "$triggers"
            fi
        done <"$alias_list_tmp"

        rm -f "$alias_list_tmp"
    fi

    # Register SHARED utility modules for lazy loading
    _register_lazy_modules_from_dir "$UTIL_DIR" "shared_util" "sh bash env"

    # Register SHELL-SPECIFIC configurations for lazy loading
    if [ -n "$SHELL_SPECIFIC_DIR" ] && [ -d "$SHELL_SPECIFIC_DIR" ]; then
        shell_specific_exts="bash sh env"
        if [ "$CURRENT_SHELL" = "zsh" ]; then
            shell_specific_exts="zsh sh bash env"
        fi

        # Register shell-specific aliases
        if [ -d "$SHELL_ALIASES_DIR" ]; then
            shell_alias_list_tmp="$(mktemp)"
            for_each_shell_file "$SHELL_ALIASES_DIR" "$shell_specific_exts" >"$shell_alias_list_tmp"

            while IFS= read -r alias_file; do
                if [ -r "$alias_file" ]; then
                    alias_stub="$(strip_shell_extension "$(basename "$alias_file")")"
                    module_name="${CURRENT_SHELL}_aliases_${alias_stub}"
                    register_lazy_module "$module_name" "$alias_file" ""
                fi
            done <"$shell_alias_list_tmp"

            rm -f "$shell_alias_list_tmp"
        fi

        # Register shell-specific utilities, completions, and prompts
        _register_lazy_modules_from_dir "$SHELL_UTIL_DIR" "${CURRENT_SHELL}_util" "$shell_specific_exts"
        _register_lazy_modules_from_dir "$SHELL_COMPLETIONS_DIR" "${CURRENT_SHELL}_completion" "$shell_specific_exts"
        _register_lazy_modules_from_dir "$SHELL_PROMPTS_DIR" "${CURRENT_SHELL}_prompt" "$shell_specific_exts"
    fi
fi

end_timing "lazy_registration" "Lazy module registration"
