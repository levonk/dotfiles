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
    value="${value//"/\\\"}"
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

    # 1. Create user
    if ! sudo useradd -m -s "$shell" "$user"; then
        echo "❌ ERROR: Failed to create user '$user'"
        return 1
    fi

    read -r -d '' script_to_run <<'EOF'
set -euo pipefail
export PATH=/usr/local/bin:/usr/bin:/bin

collect_startup_env() {
    local shell_path="$1"
    local shell_label="$2"

    if [ -z "$shell_path" ] || [ ! -x "$shell_path" ]; then
        printf '  WARNING: shell for STARTUP_TEST_ENV collection missing or not executable: %s\n' "$shell_path" >&2
        return 1
    fi

    local -a shell_cmd
    case "$shell_label" in
        zsh)
            shell_cmd=("$shell_path" "-d" "-f" "-c")
{{ ... }}
fi
. "$ENTRYPOINT_RC"
printf "__STARTUP_TEST_ENV__=%s\n" "${STARTUP_TEST_ENV-}"
'

    local output
    if ! output="$("${shell_cmd[@]}" "$script_body" 2>&1)"; then
        printf '%s\n' "$output" >&2
        printf '  WARNING: Failed to collect STARTUP_TEST_ENV for shell=%s path=%s\n' "$shell_label" "$shell_path" >&2
        return 1
    fi

    printf '%s|user=%s|shell=%s|shell_path=%s\n' "$output" "$USER" "$shell_label" "$shell_path"
}

# Create a writable copy of the dotfiles repo owned by the current user
DOTFILES_COPY="$HOME/dotfiles-copy"
mkdir -p "$DOTFILES_COPY"
cp -r /workspace/. "$DOTFILES_COPY/"

# Run chezmoi from within the writable copy
cd "$DOTFILES_COPY"
chezmoi init --apply

collect_startup_env "${SHELL_UNDER_TEST:-$SHELL}" "${SHELL_LABEL:-$(basename "${SHELL_UNDER_TEST:-$SHELL}")}" || true
EOF

    local script_output
    local script_status=0
    if ! script_output="$(SHELL_UNDER_TEST="$shell" SHELL_LABEL="$(basename "$shell")" sudo -H -u "$user" /bin/bash <<< "$script_to_run" 2>&1)"; then
{{ ... }}
    fi

    printf '%s\n' "$script_output"

    local startup_line
    startup_line="$(printf '%s\n' "$script_output" | grep '^__STARTUP_TEST_ENV__=' || true)"
    if [ -n "$startup_line" ]; then
        tokens="${startup_line#__STARTUP_TEST_ENV__=}"
        case "$tokens" in
            *'|user='*)
                tokens="${tokens%%|user=*}"
                ;;
        esac
        printf '__STARTUP_TEST_ENV__=%s|user=%s|shell=%s\n' "$tokens" "$user" "$shell" >>"$STARTUP_ENV_LOG"
        append_startup_json "$user" "$(basename "$shell")" "$shell" "$tokens"
    else
        printf '⚠️  WARNING: STARTUP_TEST_ENV not emitted for user=%s shell=%s\n' "$user" "$shell"
        test_failures=1
    fi

    if [ "$script_status" -ne 0 ]; then
        echo "❌ ERROR: chezmoi failed for user '$user'"
        test_failures=1
    fi

    # 3. Clean up user
    sudo userdel -r "$user" 2>/dev/null || true

    if [ "$test_failures" -eq 0 ]; then
        echo "✅ Tests passed for user '$user'"
    fi

    return "$test_failures"
}

# --- Main --- 
echo "🚀 Executing Ultra-Minimal Test Suite..."

FINAL_RC=0

# Run for zsh user
if command -v zsh >/dev/null 2>&1; then
    run_chezmoi_test_for_user "testuser-zsh" "/bin/zsh" || FINAL_RC=$?
else
    echo "⚠️ Skipping zsh test: zsh not found."
fi

# Run for bash user
if command -v bash >/dev/null 2>&1; then
    run_chezmoi_test_for_user "testuser-bash" "/bin/bash" || FINAL_RC=$?
else
    echo "⚠️ Skipping bash test: bash not found."
fi

# --- Final Report ---
if [ "$FINAL_RC" -eq 0 ]; then
    echo "🎉 All tests passed successfully!"
    exit 0
else
    echo "🔥 Some tests failed."
    exit "$FINAL_RC"
fi
