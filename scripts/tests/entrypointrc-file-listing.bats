#!/usr/bin/env bats
# =====================================================================
# Entrypointrc File Listing Tests
# Purpose:
#   - Isolate and verify the file enumeration logic mirrored from
#     home/current/dot_config/shells/shared/entrypointrc.sh
#   - Exercise the function chain that builds configurable file lists
#     without external dependencies
# =====================================================================

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

module_debug_enter() { :; }
module_debug_exit() { :; }

enhanced_safe_source() {
    local file_path="$1"
    local description="${2:-$(basename "$1" 2>/dev/null || echo "$1")}" 

    ENTRYPOINT_SOURCE_COUNT=$((ENTRYPOINT_SOURCE_COUNT + 1))
    printf '%s|%s\n' "$file_path" "$description" >>"$ENTRYPOINT_FILE_LOG_PATH"
}

_source_modules_from_dir() {
    local dir_path="$1"
    local desc_prefix="$2"
    local shell_exts="$3"
    local sort_mode="0"
    local exclude_pattern=""
    local file_path

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
            if [ -n "$exclude_pattern" ]; then
                if printf '%s\n' "$file_basename" | grep -qE -- "$exclude_pattern"; then
                    continue
                fi
            fi
            enhanced_safe_source "$file_path" "${desc_prefix}: $(strip_shell_extension "$file_basename")"
        fi
    done <"$list_tmp"

    rm -f "$list_tmp"

    module_debug_exit "$dir_path"
}

setup() {
    TEST_ROOT="$(mktemp -d)"
    FIXTURE_DIR="${TEST_ROOT}/fixtures"
    mkdir -p "$FIXTURE_DIR"
    ENTRYPOINT_FILE_LOG_PATH="$(mktemp)"
    ENTRYPOINT_SOURCE_COUNT=0
}

teardown() {
    rm -rf "$TEST_ROOT" 2>/dev/null || true
    rm -f "$ENTRYPOINT_FILE_LOG_PATH" 2>/dev/null || true
}

create_fixture_files() {
    local target_dir="$1"
    shift

    mkdir -p "$target_dir"

    for file_spec in "$@"; do
        local path custom_data
        path="${file_spec%%:*}"
        custom_data="${file_spec#*:}"
        touch "$target_dir/$path"
        if [ "$custom_data" != "$path" ]; then
            printf '%s\n' "$custom_data" > "$target_dir/$path"
        fi
    done
}

@test "_source_modules_from_dir respects exclude patterns" {
    create_fixture_files "$FIXTURE_DIR/exclude" \
        "keep.sh" \
        "skip.env" \
        "skip.sh"

    : >"$ENTRYPOINT_FILE_LOG_PATH"
    ENTRYPOINT_SOURCE_COUNT=0
    _source_modules_from_dir "$FIXTURE_DIR/exclude" "Shared" "sh env" 0 '^skip\.(sh|env)$'

    expected="${FIXTURE_DIR}/exclude/keep.sh|Shared: keep"
    result_log="$(cat "$ENTRYPOINT_FILE_LOG_PATH")"
    [ "$result_log" = "$expected" ]
    [ "$ENTRYPOINT_SOURCE_COUNT" -eq 1 ]
}

@test "_source_modules_from_dir captures descriptions using strip_shell_extension" {
    create_fixture_files "$FIXTURE_DIR/descriptions" \
        "alpha.sh" \
        "beta.env"

    : >"$ENTRYPOINT_FILE_LOG_PATH"
    ENTRYPOINT_SOURCE_COUNT=0
    _source_modules_from_dir "$FIXTURE_DIR/descriptions" "Shared" "sh env"

    expected="${FIXTURE_DIR}/descriptions/alpha.sh|Shared: alpha
${FIXTURE_DIR}/descriptions/beta.env|Shared: beta"

    result_log="$(cat "$ENTRYPOINT_FILE_LOG_PATH")"
    [ "$(printf '%s\n' "$result_log" | sort)" = "$(printf '%s\n' "$expected" | sort)" ]
    [ "$ENTRYPOINT_SOURCE_COUNT" -eq 2 ]
}
