#!/bin/bash
# generate-ssh-key.bash - Dynamic SSH key generation script
# 
# This script generates SSH keys on-demand using a consistent naming format.
# Designed for use in SSH Match directives and general SSH key management.
#
# Usage: generate-ssh-key.bash [hostname] [username] [--signed] [--key-type TYPE]
#
# Arguments:
#   hostname    - Target hostname (default: current hostname)
#   username    - Git username (default: auto-detected from CHEZMOI_GIT_USER, USER, etc.)
#   --signed    - Generate a signed/expiring key (requires SSH CA setup)
#   --key-type  - Key type: ed25519 (default), rsa, ecdsa
#
# Exit codes:
#   0 - Key already exists (no action taken)
#   1 - New key generated successfully
#   2 - Error occurred during key generation
#
# Key naming format: {hostname}-{username}-{service}-{username}-{keytype}
# Example: laptop-alice-github-alice-ed25519

set -euo pipefail

# Script configuration
SCRIPT_NAME="$(basename "$0")"
SSH_DIR="$HOME/.ssh"
DEFAULT_KEY_TYPE="ed25519"
DEFAULT_EXPIRY_DAYS="365"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $*" >&2
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $*" >&2
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*" >&2
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $*" >&2
}

# Usage function
usage() {
    cat >&2 << EOF
${CYAN}${SCRIPT_NAME}${NC} - Dynamic SSH Key Generation

${YELLOW}USAGE:${NC}
    $SCRIPT_NAME [hostname] [username] [options]

${YELLOW}ARGUMENTS:${NC}
    hostname        Target hostname (default: $(hostname))
    username        Git username (default: auto-detected)

${YELLOW}OPTIONS:${NC}
    --signed        Generate signed/expiring key (requires SSH CA)
    --key-type TYPE Key type: ed25519 (default), rsa, ecdsa
    --expiry DAYS   Expiry in days for signed keys (default: $DEFAULT_EXPIRY_DAYS)
    --service NAME  Service name for key (default: derived from hostname)
    --help, -h      Show this help message

${YELLOW}EXAMPLES:${NC}
    $SCRIPT_NAME                           # Generate key for current host/user
    $SCRIPT_NAME github.com alice          # Generate key for github.com as alice
    $SCRIPT_NAME --signed --expiry 90      # Generate signed key expiring in 90 days
    $SCRIPT_NAME --key-type rsa            # Generate RSA key instead of Ed25519

${YELLOW}KEY NAMING FORMAT:${NC}
    {hostname}-{username}-{service}-{username}-{keytype}
    Example: laptop-alice-github-alice-ed25519

${YELLOW}EXIT CODES:${NC}
    0 - Key already exists (no action taken)
    1 - New key generated successfully  
    2 - Error occurred during key generation

${YELLOW}SSH MATCH USAGE:${NC}
    Match host github.com exec "${XDG_BIN_HOME:-$HOME/.local/bin}/generate-ssh-key.bash github.com %r"
        IdentityFile ~/.ssh/%h-%r-github-%r-ed25519

EOF
}

# Auto-detect git username using same logic as chezmoi templates
detect_git_user() {
    local git_user=""
    
    # Priority order: CHEZMOI_GIT_USER > USER > USERNAME > whoami > "user"
    if [[ -n "${CHEZMOI_GIT_USER:-}" ]]; then
        git_user="$CHEZMOI_GIT_USER"
    elif [[ -n "${USER:-}" ]]; then
        git_user="$USER"
    elif [[ -n "${USERNAME:-}" ]]; then
        git_user="$USERNAME"
    elif command -v whoami >/dev/null 2>&1; then
        git_user="$(whoami)"
    else
        git_user="user"
    fi
    
    echo "$git_user"
}

# Extract service name from hostname
extract_service() {
    local hostname="$1"
    local service=""
    
    case "$hostname" in
        *github.com*) service="github" ;;
        *gitlab.com*) service="gitlab" ;;
        *bitbucket.org*) service="bitbucket" ;;
        *codeberg.org*) service="codeberg" ;;
        *gitea.com*) service="gitea" ;;
        *sourceforge.net*) service="sourceforge" ;;
        *launchpad.net*) service="launchpad" ;;
        *) 
            # Extract domain without TLD for generic services
            service="$(echo "$hostname" | sed 's/.*\.\([^.]*\)\.[^.]*$/\1/' | sed 's/[^a-zA-Z0-9]//g')"
            if [[ -z "$service" || "$service" == "$hostname" ]]; then
                service="$(echo "$hostname" | sed 's/[^a-zA-Z0-9]//g')"
            fi
            ;;
    esac
    
    echo "$service"
}

# Generate SSH key
generate_key() {
    local hostname="$1"
    local username="$2"
    local key_type="$3"
    local signed="$4"
    local expiry_days="$5"
    local service="$6"
    
    # Create key filename
    local key_name="${hostname}-${username}-${service}-${username}-${key_type}"
    local key_path="$SSH_DIR/$key_name"
    local pub_key_path="${key_path}.pub"
    
    # Check if key already exists
    if [[ -f "$key_path" ]]; then
        log_info "SSH key already exists: $key_name"
        return 0
    fi
    
    # Ensure SSH directory exists
    mkdir -p "$SSH_DIR"
    chmod 700 "$SSH_DIR"
    
    log_info "Generating $key_type SSH key: $key_name"
    
    # Prepare key generation parameters
    local ssh_keygen_args=()
    local comment="${hostname}-${username}@${service}"
    
    case "$key_type" in
        ed25519)
            ssh_keygen_args+=(-t ed25519)
            ;;
        rsa)
            ssh_keygen_args+=(-t rsa -b 4096)
            ;;
        ecdsa)
            ssh_keygen_args+=(-t ecdsa -b 521)
            ;;
        *)
            log_error "Unsupported key type: $key_type"
            return 2
            ;;
    esac
    
    # Add common parameters
    ssh_keygen_args+=(-f "$key_path")
    ssh_keygen_args+=(-C "$comment")
    ssh_keygen_args+=(-N "")  # No passphrase
    
    # Generate the key
    if ! ssh-keygen "${ssh_keygen_args[@]}"; then
        log_error "Failed to generate SSH key"
        return 2
    fi
    
    # Set proper permissions
    chmod 600 "$key_path"
    chmod 644 "$pub_key_path"
    
    # Handle signed keys if requested
    if [[ "$signed" == "true" ]]; then
        generate_signed_key "$key_path" "$expiry_days" "$comment"
    fi
    
    # Output success information
    log_success "Generated SSH key: $key_name"
    log_info "Key type: $key_type"
    log_info "Comment: $comment"
    log_info "Private key: $key_path"
    log_info "Public key: $pub_key_path"
    
    if [[ "$signed" == "true" ]]; then
        log_info "Certificate: ${key_path}-cert.pub"
        log_info "Expires: $(ssh-keygen -L -f "${key_path}-cert.pub" | grep Valid | head -1)"
    fi
    
    echo >&2
    log_info "=== PUBLIC KEY (copy this to your VCS provider) ==="
    cat "$pub_key_path" >&2
    echo >&2
    
    log_info "=== SSH CONFIG USAGE ==="
    cat >&2 << EOF
Add to your SSH config (~/.ssh/config):

Host ${service}-l
    HostName ${hostname}
    User git
    IdentityFile ${key_path}
    IdentitiesOnly yes

Or use in Match directive:
Match host ${hostname}
    IdentityFile ${key_path}
EOF
    
    return 1  # New key generated
}

# Generate signed key (requires SSH CA setup)
generate_signed_key() {
    local key_path="$1"
    local expiry_days="$2"
    local comment="$3"
    
    log_info "Attempting to generate signed certificate..."
    
    # Check if SSH CA is available
    local ca_key="$SSH_DIR/ca-key"
    if [[ ! -f "$ca_key" ]]; then
        log_warn "SSH CA key not found at $ca_key"
        log_warn "Signed key generation skipped"
        return 0
    fi
    
    # Calculate expiry date
    local expiry_date
    if command -v date >/dev/null 2>&1; then
        if date --version >/dev/null 2>&1; then
            # GNU date
            expiry_date="$(date -d "+${expiry_days} days" +%Y%m%d)"
        else
            # BSD date (macOS)
            expiry_date="$(date -v+${expiry_days}d +%Y%m%d)"
        fi
    else
        log_warn "Date command not available, using default expiry"
        expiry_date="$(printf '%(%Y%m%d)T' $(($(printf '%(%s)T') + expiry_days * 86400)))"
    fi
    
    # Generate certificate
    local cert_path="${key_path}-cert.pub"
    if ssh-keygen -s "$ca_key" -I "$comment" -V "+${expiry_days}d" "${key_path}.pub"; then
        log_success "Generated signed certificate: $(basename "$cert_path")"
        chmod 644 "$cert_path"
    else
        log_warn "Failed to generate signed certificate"
    fi
}

# Main function
main() {
    local hostname=""
    local username=""
    local key_type="$DEFAULT_KEY_TYPE"
    local signed="false"
    local expiry_days="$DEFAULT_EXPIRY_DAYS"
    local service=""
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --help|-h)
                usage
                exit 0
                ;;
            --signed)
                signed="true"
                shift
                ;;
            --key-type)
                key_type="$2"
                shift 2
                ;;
            --expiry)
                expiry_days="$2"
                shift 2
                ;;
            --service)
                service="$2"
                shift 2
                ;;
            -*)
                log_error "Unknown option: $1"
                usage
                exit 2
                ;;
            *)
                if [[ -z "$hostname" ]]; then
                    hostname="$1"
                elif [[ -z "$username" ]]; then
                    username="$1"
                else
                    log_error "Too many arguments: $1"
                    usage
                    exit 2
                fi
                shift
                ;;
        esac
    done
    
    # Set defaults
    if [[ -z "$hostname" ]]; then
        hostname="$(hostname)"
    fi
    
    if [[ -z "$username" ]]; then
        username="$(detect_git_user)"
    fi
    
    if [[ -z "$service" ]]; then
        service="$(extract_service "$hostname")"
    fi
    
    # Validate inputs
    if [[ -z "$hostname" || -z "$username" || -z "$service" ]]; then
        log_error "Failed to determine hostname, username, or service"
        log_error "Hostname: $hostname"
        log_error "Username: $username"
        log_error "Service: $service"
        exit 2
    fi
    
    # Validate key type
    case "$key_type" in
        ed25519|rsa|ecdsa) ;;
        *)
            log_error "Invalid key type: $key_type"
            log_error "Supported types: ed25519, rsa, ecdsa"
            exit 2
            ;;
    esac
    
    # Generate the key
    generate_key "$hostname" "$username" "$key_type" "$signed" "$expiry_days" "$service"
}

# Run main function
main "$@"
