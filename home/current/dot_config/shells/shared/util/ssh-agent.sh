#!/usr/bin/env sh
# shellcheck shell=sh
#{{- includeTemplate "dot_config/ai/templates/shell/sourceable.sh.tmpl" (dict "path" .path "name" .name) -}}


# =====================================================================

#!/usr/bin/env sh
# This file is managed by chezmoi (https://www.chezmoi.io/) and maintained at https://github.com/levonk/dotfiles

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

# Find all valid private keys in ~/.ssh
# - excludes: *.pub, *.cert, known_hosts*, config*, *.bak
# - do NOT pre-validate with ssh-keygen to allow passphrase prompts in ssh-add
find_ssh_private_keys() {
    find "$HOME/.ssh" -maxdepth 1 -type f \
      ! -name '*.pub' ! -name '*.cert' \
      ! -name 'known_hosts*' ! -name '*config*' ! -name 'authorized_keys*' \
      ! -name '*.bak'
}

# Auto-add validated private keys by default when no keys are loaded
# ssh-add will prompt for passphrases if needed; otherwise silent success
if command -v ssh-add >/dev/null 2>&1; then
    if ! ssh-add -l >/dev/null 2>&1; then
        keys_to_add="$(find_ssh_private_keys)"
        if [ -n "$keys_to_add" ]; then
            # Try adding each candidate; ssh-add will prompt for passphrases
            # Ignore non-key files silently (quick header check)
            if [ "${SSH_AGENT_AUTOADD_PROMPT:-0}" = "1" ]; then
                # Opt-in behavior: allow prompting for passphrases via /dev/tty if available
                printf "%s\n" "$keys_to_add" | while IFS= read -r _key; do
                    [ -n "$_key" ] || continue
                    if head -n1 "$_key" 2>/dev/null | grep -qi 'PRIVATE KEY'; then
                        if [ -r /dev/tty ]; then
                            ssh-add "$_key" </dev/tty || true
                        else
                            ssh-add "$_key" || true
                        fi
                    fi
                done
            else
                # Default behavior: non-blocking; only auto-add unencrypted keys
                printf "%s\n" "$keys_to_add" | while IFS= read -r _key; do
                    [ -n "$_key" ] || continue
                    # Quick header check to skip obvious non-keys
                    if head -n1 "$_key" 2>/dev/null | grep -qi 'PRIVATE KEY'; then
                        # Only auto-add keys that do NOT require a passphrase to avoid login prompts/hangs
                        # ssh-keygen with an empty passphrase will succeed only for unencrypted keys
                        if command -v ssh-keygen >/dev/null 2>&1 && ssh-keygen -y -P "" -f "$_key" >/dev/null 2>&1; then
                            ssh-add "$_key" >/dev/null 2>&1 || true
                        else
                            : # Skip passphrase-protected keys to avoid blocking
                        fi
                    fi
                done
            fi
        fi
    fi
fi
