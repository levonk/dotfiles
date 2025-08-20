#!/bin/sh
# Robust SSH config updater script
# Safely updates ~/.ssh/config with default settings if not already present
# Works on any Unix-like system with POSIX-compliant shell

set -e

# Define the config block to add (using printf for better compatibility)
CONFIG_BLOCK="# Default SSH settings\nHost *\n    ForwardAgent no\n    ForwardX11 no\n    Compression yes\n    ServerAliveInterval 30\n    ServerAliveCountMax 3\n    TCPKeepAlive yes\n    IdentitiesOnly yes\n    AddKeysToAgent yes\n    UseKeychain yes\n    AddressFamily inet\n    Protocol 2\n    StrictHostKeyChecking ask\n    HashKnownHosts yes\n    Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com,aes256-ctr,aes192-ctr,aes128-ctr\n    MACs hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com,umac-128-etm@openssh.com\n    KexAlgorithms curve25519-sha256@libssh.org,diffie-hellman-group-exchange-sha256\n    HostKeyAlgorithms ssh-ed25519,ssh-rsa"

# Create a temporary file for atomic updates
create_temp_file() {
    mktemp 2>/dev/null || mktemp -t 'sshconfig'
}

# Backup the current config
backup_file() {
    local file="$1"
    local timestamp
    timestamp=$(date +%Y%m%d_%H%M%S 2>/dev/null || date '+%Y%m%d_%H%M%S')
    cp "$file" "${file}.bak.${timestamp}" 2>/dev/null || {
        echo "Warning: Could not create backup of $file" >&2
        return 1
    }
    echo "Created backup at ${file}.bak.${timestamp}" >&2
}

# Check if file contains a specific pattern
file_contains() {
    local file="$1"
    local pattern="$2"
    # Use grep -q if available, otherwise use simple grep
    { grep -q "$pattern" "$file" 2>/dev/null || grep "$pattern" "$file" >/dev/null 2>&1; }
}

# Main function
main() {
    local ssh_config="${HOME}/.ssh/config"
    local temp_file
    
    # Create .ssh directory if it doesn't exist
    mkdir -p "$(dirname "$ssh_config")" || {
        echo "Error: Could not create .ssh directory" >&2
        return 1
    }
    
    # Create config file if it doesn't exist
    if [ ! -f "$ssh_config" ]; then
        touch "$ssh_config" || {
            echo "Error: Could not create $ssh_config" >&2
            return 1
        }
        chmod 600 "$ssh_config"
    fi
    
    # Create a backup
    backup_file "$ssh_config" || {
        echo "Warning: Continuing without backup" >&2
    }
    
    # Check if the config block already exists
    if file_contains "$ssh_config" "# Default SSH settings"; then
        echo "SSH config already contains default settings, no changes made" >&2
        return 0
    fi
    
    # Create temp file
    temp_file=$(create_temp_file) || {
        echo "Error: Could not create temporary file" >&2
        return 1
    }
    
    # Add existing content and new config block to temp file
    { 
        # Preserve existing content
        [ -s "$ssh_config" ] && cat "$ssh_config"
        # Add separator and new config
        printf '\n# ===== Added by update-ssh-config.sh =====\n%s\n' "$CONFIG_BLOCK"
    } > "$temp_file"
    
    # Atomically replace the original file
    if mv -f "$temp_file" "$ssh_config" 2>/dev/null; then
        # Set strict permissions
        chmod 600 "$ssh_config"
        echo "Successfully updated SSH config with secure defaults" >&2
    else
        echo "Error: Failed to update SSH config" >&2
        rm -f "$temp_file" 2>/dev/null || true
        return 1
    fi
}

# Run the main function
main "$@"

exit 0
