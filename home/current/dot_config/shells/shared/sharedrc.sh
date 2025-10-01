#!/usr/bin/env sh
# shellcheck shell=sh
#{{- includeTemplate "dot_config/ai/templates/shell/sourceable.sh.tmpl" (dict "path" .path "name" .name) -}}


# =====================================================================

# =====================================================================
# Universal Shared RC (shell-neutral)
# Managed by chezmoi | https://github.com/levonk/dotfiles
# Purpose:
#   - Provides all logic, aliases, and env setup shared by all shells (Bash, Zsh, etc.)
#   - Sourced by all shell-specific rc files for DRY modularization
# Shell Support:
#   - Safe for POSIX shells (Bash, Zsh, Dash, etc.)
#   - Extensible: add more shared logic as needed
# Security: No sensitive data, no unsafe calls
# Compliance: See LICENSE and admin/licenses.md
# =====================================================================

# Define base directories for sourcing (XDG compliant)
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
SHELLS_SHARED_DIR="$XDG_CONFIG_HOME/shells/shared"
ENV_DIR="$SHELLS_SHARED_DIR/env"
UTIL_DIR="$SHELLS_SHARED_DIR/util"
ALIASES_DIR="$SHELLS_SHARED_DIR/aliases"

# Optional: init tracing and skip list
# Enable with: export SHELL_INIT_TRACE=1
# Optionally skip files by substring match (space-separated): export SHELL_INIT_SKIP="ec2-env.sh docker-env.sh"
_dot_trace() {
    [ "${SHELL_INIT_TRACE:-0}" = "1" ] || return 0
    printf "[init] %s\n" "$*" >&2
}

# Optional: module load entry/exit notifications
# Enable with: export DEBUG_MODULE_LOAD=1 (fallback to DEBUG_MODULE_LOADING)
if ! command -v module_debug_enabled >/dev/null 2>&1; then
    module_debug_enabled() {
        case "${DEBUG_MODULE_LOAD:-${DEBUG_MODULE_LOADING:-0}}" in
            1|true|TRUE|True|on|ON|On) return 0 ;;
            *) return 1 ;;
        esac
    }
fi

if ! command -v module_debug_label >/dev/null 2>&1; then
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
fi

if ! command -v module_debug_enter >/dev/null 2>&1; then
    module_debug_enter() {
        module_debug_enabled || return 0
        printf '####### [ENTERING] %s\n' "$(module_debug_label "$1")" >&2
    }
fi

if ! command -v module_debug_exit >/dev/null 2>&1; then
    module_debug_exit() {
        module_debug_enabled || return 0
        if [ -n "$2" ]; then
            printf '##### [EXITING] %s [%s]\n' "$(module_debug_label "$1")" "$2" >&2
        else
            printf '##### [EXITING] %s\n' "$(module_debug_label "$1")" >&2
        fi
    }
fi

_dot_modlog() {
    module_debug_enabled || return 0

    local _raw="$*"
    local _action=${_raw%% *}
    local _rest=${_raw#"$_action"}

    # Trim leading spaces from the remainder
    while [ "${_rest# }" != "$_rest" ]; do
        _rest=${_rest# }
    done

    local _category=${_rest%%:*}
    local _path_and_status=${_rest#*: }
    local _status=""
    local _path="$_path_and_status"

    case "$_path_and_status" in
        *' status='*)
            _status=${_path_and_status##* status=}
            _path=${_path_and_status% status=*}
            ;;
    esac

    case "$_action" in
        ENTER)
            module_debug_enter "$_path"
            ;;
        EXIT)
            module_debug_exit "$_path" "${_status:+${_category}:${_status}}"
            ;;
        *)
            printf '[mod] %s\n' "$_raw" >&2
            ;;
    esac
}

_dot_should_skip() {
    # Usage: _dot_should_skip <filepath>; returns 0 if should skip
    _f="$1"
    [ -n "$SHELL_INIT_SKIP" ] || return 1
    for _p in $SHELL_INIT_SKIP; do
        case "$_f" in
            *"$_p"*) return 0;;
        esac
    done
    return 1
}

# Optional: per-file sourcing timeout (seconds)
# Set SHELL_INIT_TIMEOUT_SECS to a positive integer to timebox each sourced file.
# Example: export SHELL_INIT_TIMEOUT_SECS=3
SHELL_INIT_TIMEOUT_SECS="${SHELL_INIT_TIMEOUT_SECS:-0}"

_dot_timebox_source() {
    # Usage: _dot_timebox_source <kind> <filepath>
    # kind is for trace messages: env|util|aliases
    _kind="$1"
    _file="$2"
    if _dot_should_skip "$_file"; then
        _dot_trace "skip $_kind: $_file"
        return 0
    fi
    _dot_modlog "ENTER $_kind: $_file"
    _dot_trace "source $_kind: $_file"
    if [ "$SHELL_INIT_TIMEOUT_SECS" -gt 0 ] && command -v timeout >/dev/null 2>&1; then
        # Use sh -c with positional to avoid quoting issues
        if ! timeout "${SHELL_INIT_TIMEOUT_SECS}s" sh -c '. "$1"' sh "$_file"; then
            _dot_trace "timeout $_kind: $_file"
            _dot_modlog "EXIT  $_kind: $_file status=timeout"
            echo "Warning: Timed out sourcing $_file after ${SHELL_INIT_TIMEOUT_SECS}s" >&2
            return 0
        fi
        _dot_modlog "EXIT  $_kind: $_file status=ok"
    else
        if . "$_file"; then
            _dot_modlog "EXIT  $_kind: $_file status=ok"
        else
            _dot_modlog "EXIT  $_kind: $_file status=failed"
            echo "Warning: Failed to source $_file" >&2
        fi
    fi
}

# Source all files in the env/ directory with safety checks (safe for empty dirs)
if [ -d "$ENV_DIR" ]; then
    module_debug_enter "$ENV_DIR"
    find "$ENV_DIR" -maxdepth 1 -type f \( -name "*.sh" -o -name "*.bash" -o -name "*.env" \) 2>/dev/null | while IFS= read -r config_file; do
        if [ -r "$config_file" ] && [ -f "$config_file" ]; then
            _dot_timebox_source env "$config_file"
        fi
    done
    module_debug_exit "$ENV_DIR"
else
    echo "Warning: env directory not found: $ENV_DIR" >&2
fi

# Source all files in the util/ directory with safety checks (safe for empty dirs)
if [ -d "$UTIL_DIR" ]; then
    module_debug_enter "$UTIL_DIR"
    find "$UTIL_DIR" -maxdepth 1 -type f \( -name "*.sh" -o -name "*.bash" -o -name "*.env" \) 2>/dev/null | while IFS= read -r util_file; do
        if [ -r "$util_file" ] && [ -f "$util_file" ]; then
            _dot_timebox_source util "$util_file"
        fi
    done
    module_debug_exit "$UTIL_DIR"
else
    echo "Warning: util directory not found: $UTIL_DIR" >&2
fi

# Source all files in the aliases/ directory with safety checks (safe for empty dirs)
if [ -d "$ALIASES_DIR" ]; then
    module_debug_enter "$ALIASES_DIR"
    find "$ALIASES_DIR" -maxdepth 1 -type f \( -name "*.sh" -o -name "*.bash" -o -name "*.env" \) 2>/dev/null | while IFS= read -r alias_file; do
        if [ -r "$alias_file" ] && [ -f "$alias_file" ]; then
            _dot_timebox_source aliases "$alias_file"
        fi
    done
    module_debug_exit "$ALIASES_DIR"
else
    echo "Warning: aliases directory not found: $ALIASES_DIR" >&2
fi

# Export for compliance and test detection
export DOTFILES_SHARED_RC_LOADED=1
