#!/bin/bash
# =====================================================================
# Git VCS Configuration Library
# Managed by chezmoi | https://github.com/levonk/dotfiles
#
# Purpose:
#   - Parse TOML configuration files for git repository management
#   - Provide unified functions for path resolution, account settings
#   - Handle SSH/HTTPS protocol selection and host aliases
#   - Support environment variable expansion and fallbacks
#
# Usage: Source this file in git-clone.sh and git-repo-init.sh
# Security: No sensitive data, safe for all environments
# =====================================================================

set -euo pipefail

# =============================================================================
# Configuration Variables
# =============================================================================
GIT_VCS_CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/git"
GIT_VCS_DATA_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/git"
GIT_VCS_CONFIG_FILE="$GIT_VCS_CONFIG_DIR/public-vcs.toml"
GIT_VCS_DATA_FILE="$GIT_VCS_DATA_DIR/public-vcs.toml"

# Default values
DEFAULT_REPO_BASE="${HOME}/p"
DEFAULT_REPO_TYPE="git"
DEFAULT_PROTOCOL="ssh"
DEFAULT_BRANCH="main"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# =============================================================================
# Logging Functions
# =============================================================================
vcs_log_info() {
    echo -e "${BLUE}[VCS-INFO]${NC} $1" >&2
}

vcs_log_success() {
    echo -e "${GREEN}[VCS-SUCCESS]${NC} $1" >&2
}

vcs_log_warning() {
    echo -e "${YELLOW}[VCS-WARNING]${NC} $1" >&2
}

vcs_log_error() {
    echo -e "${RED}[VCS-ERROR]${NC} $1" >&2
}

vcs_log_debug() {
    [[ "${DEBUG_VCS:-}" == "1" ]] && echo -e "${BLUE}[VCS-DEBUG]${NC} $1" >&2
}

# =============================================================================
# TOML Parsing Functions (Simple bash-based parser)
# =============================================================================
parse_toml_value() {
    local file="$1"
    local key="$2"
    local default="${3:-}"
    
    if [[ ! -f "$file" ]]; then
        echo "$default"
        return
    fi
    
    # Handle nested keys like accounts.levonk.user.email
    local section=""
    local target_section=""
    local target_key=""
    
    if [[ "$key" =~ ^([^.]+)\.(.+)\.([^.]+)$ ]]; then
        target_section="${BASH_REMATCH[1]}.${BASH_REMATCH[2]}"
        target_key="${BASH_REMATCH[3]}"
    elif [[ "$key" =~ ^([^.]+)\.([^.]+)$ ]]; then
        target_section="${BASH_REMATCH[1]}"
        target_key="${BASH_REMATCH[2]}"
    else
        target_section=""
        target_key="$key"
    fi
    
    local in_target_section=false
    local value=""
    
    while IFS= read -r line; do
        # Skip comments and empty lines
        [[ "$line" =~ ^[[:space:]]*# ]] && continue
        [[ "$line" =~ ^[[:space:]]*$ ]] && continue
        
        # Check for section headers
        if [[ "$line" =~ ^\[([^\]]+)\] ]]; then
            section="${BASH_REMATCH[1]}"
            if [[ "$section" == "$target_section" ]]; then
                in_target_section=true
            else
                in_target_section=false
            fi
            continue
        fi
        
        # Parse key-value pairs
        if [[ "$line" =~ ^[[:space:]]*([^=]+)[[:space:]]*=[[:space:]]*(.+)$ ]]; then
            local current_key="${BASH_REMATCH[1]// /}"
            local current_value="${BASH_REMATCH[2]}"
            
            # Remove quotes from value
            current_value="${current_value#\"}"
            current_value="${current_value%\"}"
            current_value="${current_value#\'}"
            current_value="${current_value%\'}"
            
            # Check if this is our target key
            if [[ -z "$target_section" && "$current_key" == "$target_key" ]] || \
               [[ "$in_target_section" == true && "$current_key" == "$target_key" ]]; then
                value="$current_value"
                break
            fi
        fi
    done < "$file"
    
    echo "${value:-$default}"
}

get_config_value() {
    local key="$1"
    local default="${2:-}"
    
    # Try data file first (user-specific), then config file (system)
    local value
    value=$(parse_toml_value "$GIT_VCS_DATA_FILE" "$key" "")
    if [[ -z "$value" ]]; then
        value=$(parse_toml_value "$GIT_VCS_CONFIG_FILE" "$key" "$default")
    fi
    
    # Expand environment variables
    value=$(envsubst <<< "$value")
    
    echo "$value"
}

# Helper function to try both private and public TOML for a given key
_try_config_key() {
    local key="$1"
    local val
    
    # Try private TOML first (user-specific data)
    val=$(parse_toml_value "$GIT_VCS_DATA_FILE" "$key" "")
    if [[ -n "$val" ]]; then
        vcs_log_debug "Found in private TOML: $key = '$val'"
        echo "$val"
        return 0
    fi
    
    # Try public TOML second (system config)
    val=$(parse_toml_value "$GIT_VCS_CONFIG_FILE" "$key" "")
    if [[ -n "$val" ]]; then
        vcs_log_debug "Found in public TOML: $key = '$val'"
        echo "$val"
        return 0
    fi
    
    return 1
}

# Get account-specific config value with ultimate hierarchy and TOML merging
# Usage: get_account_config_value url_parts_array "setting.key" "default_value"
get_account_config_value() {
    local -n url_parts_ref=$1
    local setting_key="$2"
    local default_value="${3:-}"
    
    local host="${url_parts_ref[host]}"
    local namespace="${url_parts_ref[namespace]}"
    local project="${url_parts_ref[project]}"
    local value
    
    # Account config resolution hierarchy with TOML merging at each level:
    # At each level, check private TOML first, then public TOML, before falling back
    # 1. Project-specific:        accounts.host.namespace.project.setting
    # 2. Host/namespace-specific: accounts.host.namespace.setting
    # 3. Host-specific:           accounts.host.setting
    # 4. Namespace-specific:      accounts.namespace.setting  
    # 5. Global fallback:         accounts.setting
    # 6. Provided default:        default_value
    
    # 1. Try project-specific config (most specific)
    if [[ -n "$host" && -n "$namespace" && -n "$project" ]]; then
        local project_key="accounts.$host.$namespace.$project.$setting_key"
        if value=$(_try_config_key "$project_key"); then
            vcs_log_debug "Using project-specific account config: $project_key = '$value'"
            echo "$value"
            return 0
        fi
        vcs_log_debug "No project-specific account config found: $project_key"
    fi
    
    # 2. Try host/namespace-specific config
    if [[ -n "$host" && -n "$namespace" ]]; then
        local host_namespace_key="accounts.$host.$namespace.$setting_key"
        if value=$(_try_config_key "$host_namespace_key"); then
            vcs_log_debug "Using host/namespace account config: $host_namespace_key = '$value'"
            echo "$value"
            return 0
        fi
        vcs_log_debug "No host/namespace account config found: $host_namespace_key"
    fi
    
    # 3. Try host-specific config
    if [[ -n "$host" ]]; then
        local host_key="accounts.$host.$setting_key"
        if value=$(_try_config_key "$host_key"); then
            vcs_log_debug "Using host-specific account config: $host_key = '$value'"
            echo "$value"
            return 0
        fi
        vcs_log_debug "No host-specific account config found: $host_key"
    fi
    
    # 4. Try namespace-specific config
    if [[ -n "$namespace" ]]; then
        local namespace_key="accounts.$namespace.$setting_key"
        if value=$(_try_config_key "$namespace_key"); then
            vcs_log_debug "Using namespace-specific account config: $namespace_key = '$value'"
            echo "$value"
            return 0
        fi
        vcs_log_debug "No namespace-specific account config found: $namespace_key"
    fi
    
    # 5. Try global fallback config
    local global_key="accounts.$setting_key"
    if value=$(_try_config_key "$global_key"); then
        vcs_log_debug "Using global account config: $global_key = '$value'"
        echo "$value"
        return 0
    fi
    
    # 6. Use provided default
    vcs_log_debug "Using provided default: $default_value"
    echo "$default_value"
}

# =============================================================================
# URL Parsing Functions
# =============================================================================
parse_git_url() {
    local url="$1"
    local -n result_ref=$2
    
    # Initialize result array
    result_ref[protocol]=""
    result_ref[host]=""
    result_ref[namespace]=""
    result_ref[project]=""
    result_ref[original_url]="$url"
    
    vcs_log_debug "Parsing URL: $url"
    
    # Handle different URL formats
    if [[ "$url" =~ ^(https?|git|ssh)://([^/]+)/([^/]+)/([^/]+)(\.git)?/?$ ]]; then
        # Protocol URLs: https://github.com/user/repo.git
        result_ref[protocol]="${BASH_REMATCH[1]}"
        result_ref[host]="${BASH_REMATCH[2]}"
        result_ref[namespace]="${BASH_REMATCH[3]}"
        result_ref[project]="${BASH_REMATCH[4]%.git}"
    elif [[ "$url" =~ ^([^@]+@)?([^:]+):([^/]+)/([^/]+)(\.git)?/?$ ]]; then
        # SSH URLs: git@github.com:user/repo.git
        result_ref[protocol]="ssh"
        result_ref[host]="${BASH_REMATCH[2]}"
        result_ref[namespace]="${BASH_REMATCH[3]}"
        result_ref[project]="${BASH_REMATCH[4]%.git}"
    elif [[ "$url" =~ /([^/]+)/([^/]+)(\.git)?/?$ ]]; then
        # Generic path ending: /user/repo.git
        result_ref[namespace]="${BASH_REMATCH[1]}"
        result_ref[project]="${BASH_REMATCH[2]%.git}"
        # Try to extract host from earlier in URL
        if [[ "$url" =~ ([^/]+)/[^/]+/[^/]+\.git ]]; then
            result_ref[host]="${BASH_REMATCH[1]}"
        fi
    else
        vcs_log_error "Unable to parse git URL: $url"
        return 1
    fi
    
    vcs_log_debug "Parsed - Protocol: ${result_ref[protocol]}, Host: ${result_ref[host]}, Namespace: ${result_ref[namespace]}, Project: ${result_ref[project]}"
    return 0
}

# =============================================================================
# Path Resolution Functions
# =============================================================================
resolve_repo_path() {
    local -n url_parts=$1
    local pattern_name="${2:-default}"
    
    # Get repository type acronym from mappings
    local repo_type
    repo_type=$(get_config_value "mappings.${url_parts[host]}" "$DEFAULT_REPO_TYPE")
    
    # Get account-specific path settings using host/namespace hierarchy
    local base_path pattern
    
    base_path=$(get_account_config_value url_parts "paths.base" "$DEFAULT_REPO_BASE")
    pattern=$(get_account_config_value url_parts "paths.pattern" "{base}/{repo_type}/{namespace}/{project}")
    
    # Expand pattern variables
    local resolved_path="$pattern"
    resolved_path="${resolved_path//\{base\}/$base_path}"
    resolved_path="${resolved_path//\{repo_type\}/$repo_type}"
    resolved_path="${resolved_path//\{namespace\}/${url_parts[namespace]}}"
    resolved_path="${resolved_path//\{project\}/${url_parts[project]}}"
    
    # Expand environment variables
    resolved_path=$(envsubst <<< "$resolved_path")
    
    vcs_log_debug "Resolved path: $resolved_path"
    echo "$resolved_path"
}

# =============================================================================
# Git Configuration Functions
# =============================================================================
configure_git_repo() {
    local -n url_parts=$1
    local repo_path="$2"
    
    vcs_log_info "Configuring git settings for ${url_parts[namespace]}/${url_parts[project]}"
    
    # Get account-specific configuration using host/namespace hierarchy
    local user_name user_email protocol host_alias
    
    user_name=$(get_account_config_value url_parts "user.name" "Git User")
    user_email=$(get_account_config_value url_parts "user.email" "user@example.com")
    protocol=$(get_account_config_value url_parts "protocol" "$DEFAULT_PROTOCOL")
    host_alias=$(get_account_config_value url_parts "host-alias" "")
    
    # Set git configuration in the repository
    if [[ -d "$repo_path/.git" ]]; then
        cd "$repo_path"
        git config user.name "$user_name"
        git config user.email "$user_email"
        
        vcs_log_success "Set git user.name = '$user_name'"
        vcs_log_success "Set git user.email = '$user_email'"
        
        # Set default branch if specified
        local default_branch
        default_branch=$(get_config_value "accounts.$namespace.init.defaultBranch" "")
        if [[ -z "$default_branch" ]]; then
            default_branch=$(get_config_value "accounts.init.defaultBranch" "$DEFAULT_BRANCH")
        fi
        
        if [[ -n "$default_branch" ]]; then
            git config init.defaultBranch "$default_branch"
            vcs_log_success "Set init.defaultBranch = '$default_branch'"
        fi
    else
        vcs_log_warning "Not a git repository: $repo_path"
    fi
}

# =============================================================================
# URL Construction Functions
# =============================================================================
construct_clone_url() {
    local -n url_parts=$1
    local force_protocol="${2:-}"
    
    local namespace="${url_parts[namespace]}"
    local host="${url_parts[host]}"
    local project="${url_parts[project]}"
    
    # Determine protocol to use
    local protocol="$force_protocol"
    if [[ -z "$protocol" ]]; then
        protocol=$(get_account_config_value url_parts "protocol" "$DEFAULT_PROTOCOL")
    fi
    
    # Get host alias for SSH (namespace-specific with fallback)
    local final_host="$host"
    if [[ "$protocol" == "ssh" ]]; then
        local host_alias
        
        # First try namespace-specific SSH alias: host/namespace -> alias
        local host_namespace_key="$host/$namespace"
        host_alias=$(get_config_value "ssh-aliases.$host_namespace_key" "")
        vcs_log_debug "Trying namespace-specific alias: ssh-aliases.$host_namespace_key = '$host_alias'"
        
        # If no namespace-specific alias, try account-specific host-alias (with host/namespace hierarchy)
        if [[ -z "$host_alias" ]]; then
            host_alias=$(get_account_config_value url_parts "host-alias" "")
            vcs_log_debug "Trying account host-alias with hierarchy: '$host_alias'"
        fi
        
        # If still no alias, try default host-only alias
        if [[ -z "$host_alias" ]]; then
            host_alias=$(get_config_value "ssh-aliases.defaults.$host" "")
            vcs_log_debug "Trying default host alias: ssh-aliases.defaults.$host = '$host_alias'"
        fi
        
        # Use the alias if found
        if [[ -n "$host_alias" ]]; then
            final_host="$host_alias"
            vcs_log_debug "Using SSH host alias: $host -> $final_host"
        else
            vcs_log_debug "No SSH alias found, using original host: $host"
        fi
    fi
    
    # Construct URL based on protocol
    local clone_url
    case "$protocol" in
        ssh)
            clone_url="git@$final_host:$namespace/$project.git"
            ;;
        https)
            clone_url="https://$host/$namespace/$project.git"
            ;;
        http)
            clone_url="http://$host/$namespace/$project.git"
            ;;
        *)
            vcs_log_warning "Unknown protocol '$protocol', using original URL"
            clone_url="${url_parts[original_url]}"
            ;;
    esac
    
    vcs_log_debug "Constructed clone URL: $clone_url (protocol: $protocol)"
    echo "$clone_url"
}

# =============================================================================
# Initialization Functions
# =============================================================================
ensure_config_files() {
    # Create config directories if they don't exist
    mkdir -p "$GIT_VCS_CONFIG_DIR" "$GIT_VCS_DATA_DIR"
    
    # Check if config files exist
    if [[ ! -f "$GIT_VCS_CONFIG_FILE" ]]; then
        vcs_log_warning "Config file not found: $GIT_VCS_CONFIG_FILE"
        vcs_log_info "Please create the configuration file or run chezmoi apply"
    fi
    
    if [[ ! -f "$GIT_VCS_DATA_FILE" ]]; then
        vcs_log_warning "Data file not found: $GIT_VCS_DATA_FILE"
        vcs_log_info "Consider creating user-specific configuration in $GIT_VCS_DATA_FILE"
    fi
}

# =============================================================================
# Validation Functions
# =============================================================================
validate_git_url() {
    local url="$1"
    declare -A url_parts
    
    if ! parse_git_url "$url" url_parts; then
        return 1
    fi
    
    if [[ -z "${url_parts[namespace]}" || -z "${url_parts[project]}" ]]; then
        vcs_log_error "Invalid git URL: missing namespace or project"
        return 1
    fi
    
    return 0
}

# =============================================================================
# Export Functions for External Use
# =============================================================================
# Make key functions available to sourcing scripts
export -f vcs_log_info vcs_log_success vcs_log_warning vcs_log_error vcs_log_debug
export -f parse_git_url resolve_repo_path configure_git_repo construct_clone_url
export -f get_config_value validate_git_url ensure_config_files

vcs_log_debug "Git VCS configuration library loaded"
