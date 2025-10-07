#!/usr/bin/env bash
set -euo pipefail

# Ultra-Minimal CI Test Runner

STARTUP_ENV_LOG="/temp/logs/startup-test-env.log"
mkdir -p "$(dirname "$STARTUP_ENV_LOG")"
: >"$STARTUP_ENV_LOG"

STARTUP_ENV_JSON="/temp/logs/startup-test-env.json"
mkdir -p "$(dirname "$STARTUP_ENV_JSON")"
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
    local status=0
    if ! output="$(ENTRYPOINT_RC="$entrypoint_rc" "${shell_cmd[@]}" "$script_body" 2>&1)"; then
        status=$?
    fi

    if [ "$status" -ne 0 ]; then
        printf '%s\n' "$output" >&2
        printf '  WARNING: Failed to collect STARTUP_TEST_ENV for shell=%s path=%s\n' "$shell_label" "$shell_path" >&2
        return "$status"
    fi

    printf '%s|user=%s|shell=%s|shell_path=%s\n' "$output" "$USER" "$shell_label" "$shell_path"

    return 0
}

# Create a writable copy of the dotfiles repo owned by the current user
DOTFILES_COPY="$HOME/dotfiles-copy"
mkdir -p "$DOTFILES_COPY"

# Run chezmoi from within the writable copy
cd "$DOTFILES_COPY"
chezmoi init --apply

collect_startup_env "${SHELL_UNDER_TEST:-$SHELL}" "${SHELL_LABEL:-$(basename "${SHELL_UNDER_TEST:-$SHELL}")}" || true
EOF

    local script_output
    local script_status=0
    if ! script_output="$(SHELL_UNDER_TEST="$shell" SHELL_LABEL="$(basename "$shell")" sudo -H -u "$user" /bin/bash <<< "$script_to_run" 2>&1)"; then
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
