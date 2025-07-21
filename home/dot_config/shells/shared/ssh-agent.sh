#!/bin/sh
# Secure SSH agent bootstrapper (shell-neutral, POSIX-compliant)
# Ensures only one agent is running, with optional key auto-add (with warning)
# Source from sharedrc or shell rc files

# Only run in interactive shells
case $- in
    *i*) ;;
      *) return;;
esac

# Check if agent is running and socket is valid
if [ -n "$SSH_AUTH_SOCK" ] && [ -S "$SSH_AUTH_SOCK" ] && ssh-add -l >/dev/null 2>&1; then
    # Agent is running and usable
    :
else
    # Start a new agent
    eval "$(ssh-agent -s)" >/dev/null
    export SSH_AUTH_SOCK
    export SSH_AGENT_PID
fi

# Find all private keys in ~/.ssh (excluding .pub files)
find_ssh_private_keys() {
    find "$HOME/.ssh" -maxdepth 1 -type f \
      \( -name 'id_*' ! -name '*.pub' ! -name '*.cert' \ ) 2>/dev/null
}

# Prompt user once to auto-add all private keys
if command -v ssh-add >/dev/null 2>&1; then
    keys_to_add="$(find_ssh_private_keys)"
    if [ -n "$keys_to_add" ]; then
        echo "[SECURITY WARNING] Do you want to auto-add all SSH private keys to the agent? (y/N)"
        echo "  This will add ALL private keys in ~/.ssh (except .pub/.cert)."
        echo "  Only do this on trusted machines!"
        read ans
        case "$ans" in
            [Yy]*)
                echo "$keys_to_add" | xargs -n1 ssh-add
                ;;
            *)
                echo "Skipping auto-add of private keys. Use 'ssh-add' manually as needed."
                ;;
        esac
    fi
fi
