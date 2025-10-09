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

@test "entrypoint STARTUP_TEST_ENV enumerates directory tokens" {
    local repo_root temp_home xdg_config_home xdg_cache_home mise_shims bun_bin

    repo_root="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
    temp_home="$BATS_TEST_TMPDIR/startup_tokens_home"
    xdg_config_home="$temp_home/.config"
    xdg_cache_home="$temp_home/.cache"
    mise_shims="$temp_home/.local/share/mise/shims"
    bun_bin="$temp_home/.local/share/bun/bin"

    mkdir -p "$temp_home" "$mise_shims" "$bun_bin"
    printf '#!/usr/bin/env sh\nexit 0\n' >"$bun_bin/bun"
    chmod +x "$bun_bin/bun"

    render_shell_config_tree "$temp_home"
    instrument_entrypoint_tree "$temp_home"

    local entrypoint
    entrypoint="$xdg_config_home/shells/shared/entrypointrc.sh"

    local shell_path shell_name other_shell tokens run_output

    for shell_path in /bin/zsh /bin/bash; do
        [ -x "$shell_path" ] || continue
        shell_name="${shell_path##*/}"

        case "$shell_name" in
            zsh)
                run zsh -d -f -c "set -o errexit -o nounset -o pipefail; trap 'exit 1' ERR; export HOME='$temp_home'; export XDG_CONFIG_HOME='$xdg_config_home'; export XDG_CACHE_HOME='$xdg_cache_home'; export DOTFILES_CACHE_DIR='$xdg_cache_home/dotfiles'; export DOTFILES_TEST_MODE=1; . '$entrypoint'; print -- STARTUP_TEST_ENV=$STARTUP_TEST_ENV"
                ;;
            bash)
                run bash -c "set -euo pipefail; export HOME='$temp_home'; export XDG_CONFIG_HOME='$xdg_config_home'; export XDG_CACHE_HOME='$xdg_cache_home'; export DOTFILES_CACHE_DIR='$xdg_cache_home/dotfiles'; export DOTFILES_TEST_MODE=1; . '$entrypoint'; printf 'STARTUP_TEST_ENV=%s\n' \"\$STARTUP_TEST_ENV\""
                ;;
            *)
                continue
                ;;
        esac

        if [ "$status" -ne 0 ]; then
            echo "--- entrypoint debug (shell=$shell_name status=$status) ---"
            echo "$output"
            echo "--- end debug ---"
        fi
        [ "$status" -eq 0 ]

        tokens="$(printf '%s\n' "$output" | awk -F= '/^STARTUP_TEST_ENV=/{print $2; exit}')"
        [ -n "$tokens" ]

        assert_token_present "$tokens" "shared/env"
        assert_token_present "$tokens" "shared/util"
        assert_token_present "$tokens" "shared/aliases"
        assert_token_present "$tokens" "shared/prompts"

        assert_token_present "$tokens" "$shell_name/env"
        assert_token_present "$tokens" "$shell_name/util"
        assert_token_present "$tokens" "$shell_name/prompts"
        assert_token_present "$tokens" "$shell_name/aliases"
        assert_token_present "$tokens" "$shell_name/completions"
        assert_token_present "$tokens" "$shell_name/plugins"

        case "$shell_name" in
            zsh) other_shell="bash" ;;
            bash) other_shell="zsh" ;;
        esac

        assert_token_absent "$tokens" "$other_shell/env"
        assert_token_absent "$tokens" "$other_shell/util"
        assert_token_absent "$tokens" "$other_shell/prompts"
        assert_token_absent "$tokens" "$other_shell/aliases"
        assert_token_absent "$tokens" "$other_shell/completions"
        assert_token_absent "$tokens" "$other_shell/plugins"
    done
}

render_shell_config_tree() {
    local dest_root="$1"
    local repo_root

    repo_root="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"

    mkdir -p "$dest_root/.config/shells"

    cp -R "$repo_root/home/current/dot_config/shells/shared" "$dest_root/.config/shells/"
    cp -R "$repo_root/home/current/dot_config/shells/zsh" "$dest_root/.config/shells/"
    cp -R "$repo_root/home/current/dot_config/shells/bash" "$dest_root/.config/shells/"
}

create_token_module() {
    local target_dir="$1"
    local label="$2"

    mkdir -p "$target_dir"

    cat >"$target_dir/shell-test.sh" <<EOF
#!/usr/bin/env sh
_entrypoint_token_dir='$label'
ENTRYPOINT_TOKEN_PATHS="${ENTRYPOINT_TOKEN_PATHS:-}"
if [ -n "\${ENTRYPOINT_TOKEN_PATHS:-}" ]; then
  ENTRYPOINT_TOKEN_PATHS="\${ENTRYPOINT_TOKEN_PATHS}:\${_entrypoint_token_dir}"
else
  ENTRYPOINT_TOKEN_PATHS="\${_entrypoint_token_dir}"
fi
export ENTRYPOINT_TOKEN_PATHS
unset _entrypoint_token_dir
EOF

    chmod +x "$target_dir/shell-test.sh" 2>/dev/null || true
}

instrument_entrypoint_tree() {
    local home_root="$1"
    local shells_root="$home_root/.config/shells"

    create_token_module "$shells_root/shared/env" "shared/env"
    create_token_module "$shells_root/shared/util" "shared/util"
    create_token_module "$shells_root/shared/aliases" "shared/aliases"

    create_token_module "$shells_root/zsh/env" "zsh/env"
    create_token_module "$shells_root/zsh/util" "zsh/util"
    create_token_module "$shells_root/zsh/aliases" "zsh/aliases"

    create_token_module "$shells_root/bash/env" "bash/env"
    create_token_module "$shells_root/bash/util" "bash/util"
    create_token_module "$shells_root/bash/aliases" "bash/aliases"
}

assert_token_present() {
    local tokens="$1"
    local needle="$2"

    [[ ":$tokens:" == *":$needle:"* ]] || {
        echo "Expected token '$needle' in '$tokens'" >&2
        return 1
    }
}

assert_token_absent() {
    local tokens="$1"
    local needle="$2"

    [[ ":$tokens:" != *":$needle:"* ]] || {
        echo "Did not expect token '$needle' in '$tokens'" >&2
        return 1
    }
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

@test "shared dirnav module survives strict zsh sourcing" {
    local repo_root dirnav_path

    repo_root="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
    dirnav_path="$repo_root/home/current/dot_config/shells/shared/util/dirnav.sh"

    run zsh -d -f -c "set -o errexit -o nounset -o pipefail; trap 'exit 1' ERR; . '$dirnav_path'"

    [ "$status" -eq 0 ]
}

@test "entrypoint loads shared env modules under strict zsh" {
    local repo_root temp_home xdg_config_home xdg_cache_home mise_shims bun_bin

    repo_root="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
    temp_home="$BATS_TEST_TMPDIR/entry_home"
    xdg_config_home="$temp_home/.config"
    xdg_cache_home="$temp_home/.cache"
    mise_shims="$temp_home/.local/share/mise/shims"
    bun_bin="$temp_home/.local/share/bun/bin"

    mkdir -p "$temp_home" "$mise_shims" "$bun_bin"
    printf '#!/usr/bin/env sh\nexit 0\n' >"$bun_bin/bun"
    chmod +x "$bun_bin/bun"

    render_shell_config_tree "$temp_home"
    instrument_entrypoint_tree "$temp_home"

    run timeout 10s zsh -d -f -c "set -o errexit -o nounset -o pipefail; trap 'exit 1' ERR; export HOME='$temp_home'; export XDG_CONFIG_HOME='$xdg_config_home'; export XDG_CACHE_HOME='$xdg_cache_home'; export DOTFILES_CACHE_DIR='$xdg_cache_home/dotfiles'; export DEBUG_MODULE_LOADING=1; . '$xdg_config_home/shells/shared/entrypointrc.sh'; print -- ENTRYPOINT_TOKEN_PATHS=\$ENTRYPOINT_TOKEN_PATHS; print -- PATH=\$PATH"

    if [ "$status" -ne 0 ]; then
        echo "--- entrypoint debug (status=$status) ---"
        echo "$output"
        echo "--- end debug ---"
    fi

    assert_token_absent "$token_line" "zsh/util"
    assert_token_absent "$token_line" "zsh/aliases"

    [[ "$output" == *"PATH=$xdg_config_home/shells/shared/shims"* ]]
    [[ "$output" == *"$bun_bin"* ]]
}
