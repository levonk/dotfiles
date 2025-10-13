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
    value="${value//$'
'/\\n}"
    value="${value//$''/\\r}"
    value="${value//$'	'/\\t}"
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

STARTUP_VARS_LOG="/temp/logs/startup-vars.log"
: >"$STARTUP_VARS_LOG"

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
    sudo -E -H -u "$user" "$shell" -c "set -euo pipefail; export PATH=/usr/local/bin:/usr/bin:/bin; export CHEZMOI_NO_SHELL_SWITCH=1; git config --global --add safe.directory /workspace; timeout 2000s /usr/local/bin/chezmoi --config ${temp_config} init --persistent-state=/tmp/chezmoi-state-$user.boltdb --cache=/tmp/chezmoi-cache-$user --source /workspace --apply --refresh-externals never --no-tty --no-pager --verbose --debug" > "$chezmoi_log" 2>&1
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

    # Now, run a login shell as the user to collect the real startup environment
    local script_output
    local script_status=0
    echo "[debug] Executing login shell for user '$user' to collect environment..."
    local command_to_run="source \"/home/$user/.config/shells/shared/env/mise-env.sh\" && /workspace/scripts/tests/capture-startup-vars.sh \"$1\" \"$2\""

    if ! script_output="$(sudo -E -H -u "$user" "$shell" -li -c "$command_to_run" -- "$user" "$shell" 2>&1)"; then
        script_status=$?
    fi
    echo "[debug] Login shell script finished with status: $script_status"

    printf '%s\n' "$script_output"

    # The output now contains a single line with all vars, parse it
    local startup_vars_line
    startup_vars_line="$(printf '%s\n' "$script_output" | grep '^__STARTUP_VARS__' || true)"

    if [ -n "$startup_vars_line" ]; then
        echo "$startup_vars_line" >>"$STARTUP_VARS_LOG"

        # Extract STARTUP_TEST_ENV for the old log format and JSON
        local startup_test_env_val
        startup_test_env_val=$(echo "$startup_vars_line" | sed -n 's/.*STARTUP_TEST_ENV=\([^|]*\).*/\1/p')

        if [ -n "$startup_test_env_val" ]; then
            printf '__STARTUP_TEST_ENV__=%s|user=%s|shell=%s\n' "$startup_test_env_val" "$user" "$shell" >>"$STARTUP_ENV_LOG"
            append_startup_json "$user" "$(basename "$shell")" "$shell" "$startup_test_env_val"
        else
            printf '  WARNING: STARTUP_TEST_ENV not emitted for user=%s shell=%s\n' "$user" "$shell"
            test_failures=1
        fi
    else
        printf '  WARNING: STARTUP_VARS not emitted for user=%s shell=%s\n' "$user" "$shell"
        test_failures=1
    fi

    if [ "$script_status" -ne 0 ]; then
        echo "❌ ERROR: Login shell script execution failed for user '$user' with status $script_status"
        test_failures=1
    fi

    sudo -E userdel -r "$user" 2>/dev/null || true

    if [ "$test_failures" -eq 0 ]; then
        echo "✅ Tests passed for user '$user'"
    fi

    return "$test_failures"
}


echo "🚀 Executing Ultra-Minimal Test Suite..."

# First, validate that all Chezmoi templates are parsable.
# This is a critical pre-flight check before running any other tests.
echo "--- Running Chezmoi template validation ---"
if ! /workspace/scripts/tests/test-chezmoi-templates.sh; then
    echo "❌ ERROR: Chezmoi template validation failed. Aborting tests."
    exit 1
fi
echo "--- Chezmoi template validation successful ---"

# Install mise, as it is required for the tests
echo "--- Installing mise ---"
curl https://mise.run | sh
sudo mv /home/vscode/.local/bin/mise /usr/local/bin/mise
eval "$(mise activate bash)"
echo "--- mise installation complete ---"


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
