#!/usr/bin/env bash
set -euo pipefail

# Ultra-Minimal CI Test Runner

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

    # 2. Run the test script as the new user
    read -r -d '' script_to_run <<'EOF'
set -euo pipefail
export PATH=/usr/local/bin:/usr/bin:/bin

# Create a writable copy of the dotfiles repo owned by the current user
DOTFILES_COPY="$HOME/dotfiles-copy"
mkdir -p "$DOTFILES_COPY"
cp -r /workspace/. "$DOTFILES_COPY/"

# Run chezmoi from within the writable copy
cd "$DOTFILES_COPY"
chezmoi init --apply
EOF

    if ! sudo -H -u "$user" /bin/bash <<< "$script_to_run"; then
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
