#!/usr/bin/env bash
set -euo pipefail

# Ultra-Minimal CI Test Runner

STARTUP_ENV_LOG="/temp/logs/startup-test-env.log"
mkdir -p "$(dirname "$STARTUP_ENV_LOG")"
: >"$STARTUP_ENV_LOG"

STARTUP_ENV_JSON="/temp/logs/startup-test-env.json"
mkdir -p "$(dirname "$STARTUP_ENV_JSON")"
: >"$STARTUP_ENV_JSON"
STARTUP_ENV_JSON_SEP=""
STARTUP_ENV_JSON_FINALIZED=0

finalize_startup_env_json() {
    if [ "$STARTUP_ENV_JSON_FINALIZED" -eq 0 ]; then
        printf ']\n' >>"$STARTUP_ENV_JSON"
        STARTUP_ENV_JSON_FINALIZED=1
    fi
}

trap finalize_startup_env_json EXIT
printf '[\n' >>"$STARTUP_ENV_JSON"

json_escape_string() {
    local value="$1"
    value="${value//\\/\\\\}"
    value="${value//\"/\\\"}"
    value="${value//$'\n'/\\n}"
    value="${value//$'\r'/\\r}"
    value="${value//$'\t'/\\t}"
    printf '%s' "$value"
}

json_array_from_colon_list() {
    local list="$1"
    if [ -z "$list" ]; then
        printf '[]'
        return 0
    fi

    local IFS=':'
    read -r -a items <<<"$list"
    local result="["
    local idx=0
    local total=${#items[@]}
    while [ $idx -lt $total ]; do
        local token="${items[$idx]}"
        token="$(json_escape_string "$token")"
        result="${result}\"${token}\""
        idx=$((idx + 1))
        if [ $idx -lt $total ]; then
            result="${result}, "
        fi
    done
    result="${result}]"
    printf '%s' "$result"
}

append_startup_json() {
    local user="$1"
    local shell="$2"
    local shell_path="$3"
    local tokens="$4"

    user="$(json_escape_string "$user")"
    shell="$(json_escape_string "$shell")"
    shell_path="$(json_escape_string "$shell_path")"
    local token_array
    token_array="$(json_array_from_colon_list "$tokens")"

    printf '%s  {"user":"%s","shell":"%s","shell_path":"%s","startupTokens":%s}\n' \
        "$STARTUP_ENV_JSON_SEP" "$user" "$shell" "$shell_path" "$token_array" >>"$STARTUP_ENV_JSON"

    STARTUP_ENV_JSON_SEP=",\n"
}

run_chezmoi_test_for_user() {
    local user="$1"
    local shell="$2"
    local test_failures=0

    echo "--- Running tests for user '$user' with shell '$shell' ---"
    set -x # Enable command tracing

    echo "[debug] Attempting to add user '$user'..."
    if ! sudo -E useradd -m -s "$shell" "$user"; then
        echo "❌ ERROR: Failed to create user '$user'"
        set +x # Disable command tracing
        return 1
    fi
    echo "[debug] User '$user' added successfully."

    # Pre-create .config dir to prevent non-fatal race condition error in chezmoi
    sudo -E -u "$user" mkdir -p "/home/$user/.config"

    # Run chezmoi as the new user to populate their home directory
    local chezmoi_log="/tmp/chezmoi_init_${user}.log"
    echo "[debug] Running chezmoi init for user '$user'..."
    # Copy the test config to a writable location, as chezmoi tries to write temporary files in the same directory.
    local temp_config="/tmp/chezmoi-test-${user}.toml"
    sudo -E -u "$user" cp "/workspace/scripts/tests/chezmoi-test.toml" "$temp_config"

    # Use a temporary, user-specific cache and state file to avoid writing to the read-only /workspace.
    sudo -E -H -u "$user" "$shell" -c "set -euo pipefail; export PATH=/usr/local/bin:/usr/bin:/bin; export CHEZMOI_NO_SHELL_SWITCH=1; git config --global --add safe.directory /workspace; timeout 600s /usr/local/bin/chezmoi --config ${temp_config} init --persistent-state=/tmp/chezmoi-state-$user.boltdb --cache=/tmp/chezmoi-cache-$user --source /workspace --apply --refresh-externals never --no-tty --no-pager --verbose --debug" > "$chezmoi_log" 2>&1
    local chezmoi_exit_code=${?}
    echo "[debug] Chezmoi init finished with exit code: $chezmoi_exit_code"

    echo "--- CHEZMOI INIT LOG for ${user} ---"
    cat "$chezmoi_log"
    echo "--- END CHEZMOI INIT LOG for ${user} ---"

    if [ "$chezmoi_exit_code" -ne 0 ]; then
        echo "❌ ERROR: chezmoi init failed for user '$user' with exit code $chezmoi_exit_code"
        echo "[debug] Attempting to remove user '$user' after failed init..."
        sudo -E userdel -r "$user" 2>/dev/null || true
        echo "[debug] User '$user' removed."
        set +x # Disable command tracing
        return 1
    fi

    # Now, run the test script as the user to collect startup environment
    local script_file
    script_file=$(mktemp)
    # Use a trap to ensure the temp file is cleaned up on function exit
    trap 'echo "[debug] Cleaning up temp file $script_file"; rm -f "$script_file"; set +x' RETURN

    read -r -d '' script_to_run <<'EOF'
export PATH=/usr/local/bin:/usr/bin:/bin

collect_startup_env() {
    local shell_path="$1"
    local shell_label="$2"

    if [ -z "$shell_path" ] || [ ! -x "$shell_path" ]; then
        printf '  WARNING: shell for STARTUP_TEST_ENV collection missing or not executable: %s\n' "$shell_path" >&2
        return 1
    fi

    local xdg_config_home="${XDG_CONFIG_HOME:-$HOME/.config}"
    local entrypoint_rc="$xdg_config_home/shells/shared/entrypointrc.sh"

    if [ ! -r "$entrypoint_rc" ]; then
        printf '  WARNING: entrypoint file missing or unreadable: %s\n' "$entrypoint_rc" >&2
        return 1
    fi

    local -a shell_cmd
    case "$shell_label" in
        zsh)
            shell_cmd=("$shell_path" "-d" "-f" "-c")
            ;;
        bash)
            shell_cmd=("$shell_path" "-c")
            ;;
        *)
            shell_cmd=("$shell_path" "-c")
            ;;
    esac

    local script_body
    read -r -d '' script_body <<'SCRIPT'
set -euo pipefail
ENTRYPOINT_RC_PATH="$ENTRYPOINT_RC"
if [ -z "$ENTRYPOINT_RC_PATH" ] || [ ! -r "$ENTRYPOINT_RC_PATH" ]; then
    printf 'entrypoint not readable: %s\n' "$ENTRYPOINT_RC_PATH" >&2
    exit 1
fi
. "$ENTRYPOINT_RC_PATH"
printf "__STARTUP_TEST_ENV__=%s\n" "${STARTUP_TEST_ENV-}"
SCRIPT

    local output=""
    local script_status=0
    if ! output="$(ENTRYPOINT_RC="$entrypoint_rc" "${shell_cmd[@]}" "$script_body" 2>&1)"; then
        script_status=$?
    fi

    if [ "$script_status" -ne 0 ]; then
        printf '%s\n' "$output" >&2
        printf '  WARNING: Failed to collect STARTUP_TEST_ENV for shell=%s path=%s\n' "$shell_label" "$shell_path" >&2
        return "$script_status"
    fi

    printf '%s|user=%s|shell=%s|shell_path=%s\n' "$output" "$USER" "$shell_label" "$shell_path"

    return 0
}

collect_startup_env "${SHELL_UNDER_TEST:-$SHELL}" "${SHELL_LABEL:-$(basename "${SHELL_UNDER_TEST:-$SHELL}")}" || true
EOF

    printf '%s' "$script_to_run" > "$script_file"
    chmod a+rx "$script_file"
    echo "[debug] Created temporary script at $script_file to collect startup env."

    local script_output
    local script_status=0
    echo "[debug] Executing startup env script for user '$user'..."
    if ! script_output="$(SHELL_UNDER_TEST="$shell" SHELL_LABEL="$(basename "$shell")" sudo -E -H -u "$user" "$shell" "$script_file" 2>&1)"; then
        script_status=$?
    fi
    echo "[debug] Startup env script finished with status: $script_status"

    printf '%s\n' "$script_output"

    local startup_line
    startup_line="$(printf '%s\n' "$script_output" | grep '^__STARTUP_TEST_ENV__=' || true)"
    if [ -n "$startup_line" ]; then
        tokens="${startup_line#__STARTUP_TEST_ENV__=}"
        # Strip the user/shell metadata if present, but do not truncate
        case "$tokens" in
            *'|user='*)
                tokens_for_log="${tokens%%|user=*}"
                ;;
            *)
                tokens_for_log="$tokens"
                ;;
        esac
        printf '__STARTUP_TEST_ENV__=%s|user=%s|shell=%s\n' "$tokens_for_log" "$user" "$shell" >>"$STARTUP_ENV_LOG"
        append_startup_json "$user" "$(basename "$shell")" "$shell" "$tokens_for_log"
    else
        printf '  WARNING: STARTUP_TEST_ENV not emitted for user=%s shell=%s\n' "$user" "$shell"
        test_failures=1
    fi

    if [ "$script_status" -ne 0 ]; then
        echo "❌ ERROR: Script execution failed for user '$user'"
        test_failures=1
    fi

    sudo -E userdel -r "$user" 2>/dev/null || true

    if [ "$test_failures" -eq 0 ]; then
        echo "✅ Tests passed for user '$user'"
    fi

    return "$test_failures"
}

echo "🚀 Executing Ultra-Minimal Test Suite..."

FINAL_RC=0

if command -v zsh >/dev/null 2>&1; then
    set +e # Temporarily disable exit-on-error
    run_chezmoi_test_for_user "testuser-zsh" "/bin/zsh"
    ZSH_RC=$?
    set -e # Re-enable exit-on-error
    if [ "$ZSH_RC" -ne 0 ]; then
        echo "❌ ZSH TEST FAILED WITH EXIT CODE: $ZSH_RC"
        FINAL_RC=$ZSH_RC
    fi
else
    echo "⚠️ Skipping zsh test: zsh not found."
fi

if command -v bash >/dev/null 2>&1; then
    run_chezmoi_test_for_user "testuser-bash" "/bin/bash" || FINAL_RC=$?
else
    echo "⚠️ Skipping bash test: bash not found."
fi

if [ "$FINAL_RC" -eq 0 ]; then
    echo "🎉 All tests passed successfully!"
    exit 0
else
    echo "🔥 Some tests failed."
    exit "$FINAL_RC"
fi
