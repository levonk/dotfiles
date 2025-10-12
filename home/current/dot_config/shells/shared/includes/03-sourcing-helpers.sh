#!/usr/bin/env sh
# shellcheck shell=sh

# =============================================================================
# 03-sourcing-helpers.sh
#
# ## Purpose
#
# - Provides a comprehensive set of helper functions for sourcing shell scripts.
# - Includes utilities for debugging, file discovery, safe sourcing with
#   redundancy checks, and lazy module registration.
# =============================================================================

# --- Debugging Utilities ---

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

# --- File and String Utilities ---

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

# --- Core Sourcing and Registration Functions ---

enhanced_safe_source() {
    local file_path="$1"
    local description="${2:-$(basename "$file_path" 2>/dev/null || echo "$file_path")}"

    if command -v is_already_sourced >/dev/null 2>&1 && is_already_sourced "$file_path"; then
        return 0
    fi

    local result=0
    if command -v cached_source >/dev/null 2>&1; then
        cached_source "$file_path" "$description" || result=$?
    elif command -v safe_source >/dev/null 2>&1; then
        safe_source "$file_path" "$description" || result=$?
    else
        if [ -r "$file_path" ]; then
            . "$file_path" || result=$?
        else
            result=1
        fi
    fi

    return $result
}

_source_modules_from_dir() {
    local dir_path="$1"
    local desc_prefix="$2"
    local shell_exts="$3"
    local sort_mode="0"
    local exclude_pattern=""
    local file_path
    local file_basename

    unalias grep 2>/dev/null || true

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
