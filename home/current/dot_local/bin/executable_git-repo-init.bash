#!/usr/bin/env bash
# =====================================================================
# Git Repository Initialization Script (Configuration-Driven)
# Managed by chezmoi | https://github.com/levonk/dotfiles
#
# Purpose:
#   - Initialize git repository with preferred branch structure
#   - Create archive tags for root commit and pre-branch state
#   - Set up environment branches and user-specific development branch
#   - Create clean GitHub Pages branch for documentation
#   - Push all branches and tags to remote
#   - Use TOML configuration for path mappings and account settings
#
# Usage: git-repo-init [remote-url] [target-directory]
# Example: git-repo-init git@github.com:user/repo.git
#
# Configuration: ~/.config/git/public-vcs.toml and ~/.local/share/git/public-vcs.toml
# Security: No sensitive data, safe for all environments
# =====================================================================

set -euo pipefail

# Source the VCS configuration library
# Source the VCS configuration library
VCS_CONFIG_PATH="$(dirname "${BASH_SOURCE[0]}")"
VCS_CONFIG_LIB="$VCS_CONFIG_PATH/executable_git-vcs-config.bash.tmpl"
if [[ ! -f "$VCS_CONFIG_LIB" ]]; then
    VCS_CONFIG_LIB="$VCS_CONFIG_PATH/git-vcs-config.bash"
fi
if [[ ! -f "$VCS_CONFIG_LIB" ]]; then
    echo "Error: VCS configuration library not found: $VCS_CONFIG_LIB" >&2
    exit 1
fi
source "$VCS_CONFIG_LIB"

# Configuration
CURRENT_YEAR=$(date +%Y)
CURRENT_USER="${USER:-${USERNAME:-$(whoami)}}"

# Legacy logging functions (keeping for compatibility)
log_info() {
    vcs_log_info "$1"
}

log_success() {
    vcs_log_success "$1"
}

log_warning() {
    vcs_log_warning "$1"
}

log_error() {
    vcs_log_error "$1"
}

# Helper for dry-run execution
run_cmd() {
    if [[ "${DRY_RUN:-false}" == "true" ]]; then
        log_info "[DRY-RUN] Would execute: $*"
        return 0
    fi
    "$@"
}

# Helper for directory changing in dry-run
run_cd() {
    local dir="$1"
    if [[ "${DRY_RUN:-false}" == "true" ]]; then
        log_info "[DRY-RUN] Would change directory to: $dir"
        if [[ -d "$dir" ]]; then
            cd "$dir"
        else
            log_warning "[DRY-RUN] Directory $dir does not exist, skipping cd. Subsequent checks may be inaccurate."
            return 0
        fi
    else
        cd "$dir"
    fi
}

# Check if we're in a git repository
check_git_repo() {
    if git rev-parse --git-dir >/dev/null 2>&1; then
        log_info "Already in a git repository"
        return 0
    else
        log_info "Not in a git repository, initializing..."
        return 1
    fi
}

# Initialize git repository
init_git_repo() {
    local target_dir="${1:-$(pwd)}"
    local default_branch

    # Get default branch using host/namespace account hierarchy
    local default_branch
    default_branch=$(get_account_config_value url_parts "init.defaultBranch" "main")

    # Change to target directory
    run_cd "$target_dir"

    if ! check_git_repo; then
        run_cmd git init --initial-branch="$default_branch"
        log_success "Git repository initialized with branch '$default_branch'"

        # Create initial commit if no commits exist
        if ! git rev-parse HEAD >/dev/null 2>&1; then
            # Create a README if it doesn't exist
            if [[ ! -f README.md ]]; then
                # Get configuration values for README template (account-specific)
                local env_branches user_branch_pattern archive_tag_pattern
                local namespace="${url_parts[namespace]:-}"

                # Try namespace-specific config first, then fallback to default
                if [[ -n "$namespace" ]]; then
                    env_branches=$(get_config_value "accounts.$namespace.init.environment-branches" "")
                    user_branch_pattern=$(get_config_value "accounts.$namespace.init.user-branch-pattern" "")
                    archive_tag_pattern=$(get_config_value "accounts.$namespace.init.archive-tag-pattern" "")
                fi

                # Fallback to default account settings
                if [[ -z "$env_branches" ]]; then
                    env_branches=$(get_config_value "accounts.init.environment-branches" "[\"env/prod\", \"env/stage\", \"env/dev\"]")
                fi
                if [[ -z "$user_branch_pattern" ]]; then
                    user_branch_pattern=$(get_config_value "accounts.init.user-branch-pattern" "u/{user}/env/dev")
                fi
                if [[ -z "$archive_tag_pattern" ]]; then
                    archive_tag_pattern=$(get_config_value "accounts.init.archive-tag-pattern" "tag/archive/{year}/{type}")
                fi

                # Expand user branch pattern
                local user_branch="${user_branch_pattern//\{user\}/$CURRENT_USER}"
                local root_tag="${archive_tag_pattern//\{year\}/$CURRENT_YEAR}"
                root_tag="${root_tag//\{type\}/git-root-node}"
                local pre_branches_tag="${archive_tag_pattern//\{year\}/$CURRENT_YEAR}"
                pre_branches_tag="${pre_branches_tag//\{type\}/pre-init-branches}"

                if [[ "${DRY_RUN:-false}" == "true" ]]; then
                    log_info "[DRY-RUN] Would create README.md with repository documentation"
                else
                    cat > README.md << EOF
# $(basename "$(pwd)")

Repository initialized with git-repo-init script (configuration-driven).

## Branch Structure

- \`$default_branch\` - Main development branch
- \`env/prod\` - Production environment
- \`env/stage\` - Staging environment
- \`env/dev\` - Development environment
- \`$user_branch\` - Personal development branch
- \`gh_pages\` - GitHub Pages documentation (if enabled)

## Archive Tags

- \`$root_tag\` - Root commit
- \`$pre_branches_tag\` - State before branch creation

## Configuration

This repository uses configuration-driven git management:
- Config: \`~/.config/git/public-vcs.toml\`
- User Data: \`~/.local/share/git/public-vcs.toml\`
EOF
                fi
            fi

            run_cmd git add README.md
            run_cmd git commit -m "feat: initial repository setup

Initialize repository with standard branch structure and documentation.
Created by git-repo-init script on $(date -Iseconds).

Configuration-driven setup with:
- Default branch: $default_branch
- User: $CURRENT_USER
- Year: $CURRENT_YEAR"
            log_success "Initial commit created"
        fi
    fi
}

# Create archive tag for root commit
create_root_tag() {
    local root_commit
    root_commit=$(git rev-list --max-parents=0 HEAD)
    local tag_name="tag/archive/$CURRENT_YEAR/git-root-node"

    if git tag -l "$tag_name" | grep -q "$tag_name"; then
        log_warning "Root tag $tag_name already exists"
    else
        run_cmd git tag -a "$tag_name" "$root_commit" -m "Archive tag for git root node

This tag marks the initial commit of the repository.
Created by git-repo-init script on $(date -Iseconds)."
        log_success "Created root archive tag: $tag_name"
    fi
}

# Create pre-branches archive tag
create_pre_branches_tag() {
    local tag_name="tag/archive/$CURRENT_YEAR/pre-init-branches"

    if git tag -l "$tag_name" | grep -q "$tag_name"; then
        log_warning "Pre-branches tag $tag_name already exists"
    else
        run_cmd git tag -a "$tag_name" HEAD -m "Archive tag before branch initialization

This tag marks the state of main branch before creating
environment and user branches.
Created by git-repo-init script on $(date -Iseconds)."
        log_success "Created pre-branches archive tag: $tag_name"
    fi
}

# Create and setup GitHub Pages branch
setup_gh_pages() {
    local gh_pages_branch="gh_pages"

    if git show-ref --verify --quiet "refs/heads/$gh_pages_branch"; then
        log_info "GitHub Pages branch already exists, cleaning it..."
        run_cmd git checkout "$gh_pages_branch"

        # Remove all files if any exist
        if [[ -n "$(git ls-files)" ]]; then
            run_cmd git rm -rf .
            run_cmd git commit -m "chore: clean GitHub Pages branch

Remove all files to prepare for documentation.
Cleaned by git-repo-init script on $(date -Iseconds)." || true
        fi
    else
        log_info "Creating clean GitHub Pages branch..."
        run_cmd git checkout --orphan "$gh_pages_branch"
        run_cmd git rm -rf . 2>/dev/null || true

        # Create basic index.html for GitHub Pages
        if [[ "${DRY_RUN:-false}" == "true" ]]; then
            log_info "[DRY-RUN] Would create index.html for GitHub Pages"
        else
            cat > index.html << EOF
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>$(basename "$(pwd)") Documentation</title>
    <style>
        body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
               max-width: 800px; margin: 0 auto; padding: 2rem; line-height: 1.6; }
        h1 { color: #333; border-bottom: 2px solid #eee; padding-bottom: 0.5rem; }
        .meta { color: #666; font-size: 0.9em; }
    </style>
</head>
<body>
    <h1>$(basename "$(pwd)") Documentation</h1>
    <p class="meta">Generated by git-repo-init on $(date)</p>
    <p>This is the GitHub Pages site for the $(basename "$(pwd)") repository.</p>
    <p>Add your documentation here.</p>
</body>
</html>
EOF
        fi

        run_cmd git add index.html
        run_cmd git commit -m "feat: initialize GitHub Pages

Create basic GitHub Pages site structure.
Created by git-repo-init script on $(date -Iseconds)."
    fi

    log_success "GitHub Pages branch ready"
}

# Create environment branches
create_environment_branches() {
    # Check if environment branches should be created using host/namespace account hierarchy
    local create_env_branches
    create_env_branches=$(get_account_config_value url_parts "init.create-environment-branches" "true")

    if [[ "$create_env_branches" != "true" ]]; then
        log_info "Environment branch creation disabled by configuration"
        return 0
    fi

    # Get environment branches from config using host/namespace account hierarchy
    local env_branches_config
    env_branches_config=$(get_account_config_value url_parts "init.environment-branches" "env/prod,env/stage,env/dev")

    # Convert comma-separated string to array (handle both TOML array and comma-separated)
    local branches
    if [[ "$env_branches_config" =~ ^\[.*\]$ ]]; then
        # TOML array format - extract values between quotes
        IFS=',' read -ra branches <<< "$(echo "$env_branches_config" | sed 's/\[//;s/\]//;s/"//g;s/ //g')"
    else
        # Comma-separated format
        IFS=',' read -ra branches <<< "$env_branches_config"
    fi

    # Switch back to main branch
    run_cmd git checkout "$DEFAULT_BRANCH"

    log_info "Creating environment branches: ${branches[*]}"
    for branch in "${branches[@]}"; do
        # Trim whitespace
        branch=$(echo "$branch" | xargs)
        if [[ -z "$branch" ]]; then
            continue
        fi

        if git show-ref --verify --quiet "refs/heads/$branch"; then
            log_warning "Branch $branch already exists"
        else
            run_cmd git checkout -b "$branch"
            log_success "Created branch: $branch"
            run_cmd git checkout "$DEFAULT_BRANCH"
        fi
    done
}

# Set up remote and push everything
setup_remote_and_push() {
    local remote_url="$1"

    if [[ -n "$remote_url" ]]; then
        # Add remote if it doesn't exist
        if ! git remote get-url origin >/dev/null 2>&1; then
            run_cmd git remote add origin "$remote_url"
            log_success "Added remote origin: $remote_url"
        else
            log_info "Remote origin already exists: $(git remote get-url origin)"
        fi

        # Push all branches
        log_info "Pushing all branches to remote..."
        run_cmd git push -u origin --all

        # Push all tags
        log_info "Pushing all tags to remote..."
        run_cmd git push origin --tags

        log_success "All branches and tags pushed to remote"
    else
        log_warning "No remote URL provided, skipping remote setup"
        log_info "To add remote later: git remote add origin <url>"
        log_info "To push: git push -u origin --all && git push origin --tags"
    fi
}

# Switch to user development branch
switch_to_user_branch() {
    # Get user branch pattern using host/namespace account hierarchy
    local user_branch_pattern
    user_branch_pattern=$(get_account_config_value url_parts "init.user-branch-pattern" "u/{user}/env/dev")

    local user_branch="${user_branch_pattern//\{user\}/$CURRENT_USER}"

    run_cmd git checkout "$user_branch"
    log_success "Switched to user development branch: $user_branch"
}

# Display final status
show_final_status() {
    echo
    log_info "Repository initialization complete!"
    echo
    echo "📋 Created branches:"
    git branch -a | sed 's/^/  /'
    echo
    echo "🏷️  Created tags:"
    git tag | grep "tag/archive/$CURRENT_YEAR" | sed 's/^/  /'
    echo
    echo "📍 Current branch: $(git branch --show-current)"
    echo
    log_info "Ready for development! 🚀"
}

# Clone repository function (extracted from old git-clone.sh logic)
clone_repository() {
    local remote_url="$1"
    local target_dir="$2"
    local -n url_parts_ref=$3

    local repo_dir="${url_parts_ref[project]}"
    local repo_path="$target_dir/$repo_dir"

    if [[ -d "$repo_dir" ]]; then
        vcs_log_warning "Directory $repo_dir already exists. Skipping clone."
    else
        # Construct the optimal clone URL based on configuration
        local clone_url
        clone_url=$(construct_clone_url url_parts_ref)
        vcs_log_info "Clone URL: $clone_url"

        # Perform the clone operation
        vcs_log_info "Cloning repository..."
        if run_cmd git clone "$clone_url" "$repo_dir"; then
            vcs_log_success "Repository cloned successfully"
        else
            vcs_log_error "Failed to clone repository"
            # Try fallback to original URL if constructed URL failed
            if [[ "$clone_url" != "$remote_url" ]]; then
                vcs_log_info "Retrying with original URL: $remote_url"
                if run_cmd git clone "$remote_url" "$repo_dir"; then
                    vcs_log_success "Repository cloned with original URL"
                else
                    vcs_log_error "Clone failed with both URLs"
                    exit 5
                fi
            else
                exit 5
            fi
        fi
    fi

    run_cd "$repo_dir"

    # Validate that the result is a git repository
    if [[ "${DRY_RUN:-false}" != "true" ]] && [[ ! -d .git ]]; then
        vcs_log_error "$PWD is not a valid git repository"
        exit 6
    fi

    echo "$PWD"
}

# Main execution
main() {
    local remote_url="${1:-}"
    local target_dir="${2:-}"
    local clone_only="${3:-false}"
    local init_only="${4:-false}"
    local cli_user="${5:-}"
    local cli_email="${6:-}"
    local dry_run_arg="${7:-false}"
    local repo_path="$(pwd)"
    local should_clone=false
    local should_init=true

    # Set global DRY_RUN variable
    export DRY_RUN="$dry_run_arg"

    # Initialize configuration
    ensure_config_files

    # If no arguments provided, show help instead of defaulting to init
    if [[ -z "$remote_url" && -z "$target_dir" && "$clone_only" == "false" && "$init_only" == "false" ]]; then
        show_help
        exit 0
    fi

    # Determine operation mode
    if [[ "$clone_only" == "true" ]]; then
        should_clone=true
        should_init=false
        vcs_log_info "Mode: Clone only"
    elif [[ "$init_only" == "true" ]]; then
        should_clone=false
        should_init=true
        vcs_log_info "Mode: Initialize only"
    elif [[ -n "$remote_url" ]]; then
        should_clone=true
        should_init=true
        vcs_log_info "Mode: Clone and initialize"
    else
        should_clone=false
        should_init=true
        vcs_log_info "Mode: Initialize current directory"
    fi

    # Handle URL parsing and path resolution
    declare -A url_parts
    if [[ -n "$remote_url" ]]; then
        if validate_git_url "$remote_url" && parse_git_url "$remote_url" url_parts; then
            log_info "Parsed repository: ${url_parts[namespace]}/${url_parts[project]}"

            # If no target directory specified, resolve from configuration
            if [[ -z "$target_dir" ]]; then
                target_dir=$(resolve_repo_path url_parts)
                log_info "Resolved target directory: $target_dir"
            fi
        else
            log_warning "Could not parse remote URL, using current directory"
        fi
    fi

    # Handle target directory
    if [[ -n "$target_dir" ]]; then
        run_cmd mkdir -p "$target_dir"
        run_cd "$target_dir"
        repo_path="$target_dir"
    fi

    # Determine user and email using shared logic
    local git_user
    local git_email
    git_user=$(determine_git_user "$cli_user")
    git_email=$(determine_git_email "$cli_email")

    log_info "Starting git repository management..."
    log_info "User: $git_user"
    log_info "Email: $git_email"
    log_info "Year: $CURRENT_YEAR"
    log_info "Repository path: $repo_path"
    [[ -n "$remote_url" ]] && log_info "Remote URL: $remote_url"
    echo

    # Clone repository if needed
    if [[ "$should_clone" == "true" ]]; then
        repo_path=$(clone_repository "$remote_url" "$target_dir" url_parts)

        # Configure git settings
        run_cmd configure_git_repo url_parts "$repo_path" "$git_user" "$git_email"

        if [[ "$clone_only" == "true" ]]; then
            # Clone-only mode: show success and exit
            vcs_log_success "Clone operation completed successfully"
            echo
            echo "Repository Path: $repo_path"
            echo "Git Configuration:"
            echo "  User Name:  $(git config user.name 2>/dev/null || echo 'Not set')"
            echo "  User Email: $(git config user.email 2>/dev/null || echo 'Not set')"
            echo "  Default Branch: $(git config init.defaultBranch 2>/dev/null || echo 'Not set')"
            echo
            printf '\a'  # Ring system bell
            return 0
        fi
    fi

    # Initialize repository structure if needed
    if [[ "$should_init" == "true" ]]; then
        # Execute initialization steps
        init_git_repo "$repo_path"
        create_root_tag
        create_pre_branches_tag

        # Check configuration for optional features (account-specific)
        local create_gh_pages create_user_branch namespace
        namespace="${url_parts[namespace]:-}"

        # Try namespace-specific config first, then fallback to default
        if [[ -n "$namespace" ]]; then
            create_gh_pages=$(get_config_value "accounts.$namespace.init.create-gh-pages" "")
            create_user_branch=$(get_config_value "accounts.$namespace.init.create-user-branch" "")
        fi

        # Fallback to default account settings
        if [[ -z "$create_gh_pages" ]]; then
            create_gh_pages=$(get_config_value "accounts.init.create-gh-pages" "true")
        fi
        if [[ -z "$create_user_branch" ]]; then
            create_user_branch=$(get_config_value "accounts.init.create-user-branch" "true")
        fi

        if [[ "$create_gh_pages" == "true" ]]; then
            setup_gh_pages
        else
            log_info "Skipping GitHub Pages setup (disabled in configuration)"
        fi

        create_environment_branches

        # Configure git settings if we have URL information and haven't already
        if [[ -n "$remote_url" ]] && [[ -v url_parts ]] && [[ "$should_clone" == "false" ]]; then
            run_cmd configure_git_repo url_parts "$repo_path" "$git_user" "$git_email"
        fi

        # Setup remote and push if URL provided and not already cloned
        if [[ -n "$remote_url" ]] && [[ "$should_clone" == "false" ]]; then
            setup_remote_and_push "$remote_url"
        fi

        # Switch to user development branch if enabled
        if [[ "$create_user_branch" == "true" ]]; then
            switch_to_user_branch
        else
            log_info "Skipping user branch creation (disabled in configuration)"
        fi

        # Show final status
        show_final_status
    fi
}

# Help function
show_usage() {
    echo "Usage: git-repo-init [OPTIONS] [remote-url] [target-directory]"
    echo "Try 'git-repo-init --help' for more information."
}

show_help() {
    cat << EOF
Git Repository Initialization Script (Configuration-Driven)

USAGE:
    git-repo-init [OPTIONS] [remote-url] [target-directory]

DESCRIPTION:
    Unified git repository management script that can clone repositories
    and/or initialize them with a standardized branch structure, archive tags,
    and GitHub Pages setup using TOML configuration files.

MODES:
    Clone Mode:       Clones repository with configuration-driven setup
    Initialize Mode:  Full repository initialization with branch structure
    Combined Mode:    Clone + initialize (default when URL provided)

FEATURES:
    • Configuration-driven repository management
    • Automatic path resolution using TOML mappings
    • Account-specific git configuration (user.name, user.email)
    • SSH/HTTPS protocol selection with host aliases
    • Configurable branch patterns and archive tags
    • Optional GitHub Pages and user branch creation
    • Environment branches based on configuration
    • Remote setup with optimal clone URLs

OPTIONS:
    -c, --clone-only  Clone repository only (skip branch structure setup)
    -i, --init-only   Initialize only (skip cloning, work in current/target dir)
    -u, --user        Specify git user name
    -e, --email       Specify git user email
    -n, --dry-run     Show what would be done without making changes
    -h, --help        Show this help message
    --usage           Show short usage information

ARGUMENTS:
    remote-url        Optional git repository URL (any protocol)
    target-directory  Optional target directory (auto-resolved if URL provided)

CONFIGURATION:
    ~/.config/git/public-vcs.toml      - System configuration
    ~/.local/share/git/public-vcs.toml - User-specific settings

EXAMPLES:
    # Initialize current directory with branch structure
    git-repo-init

    # Clone and initialize with full setup
    git-repo-init git@github.com:user/repo.git

    # Clone only (like old git-clone.sh)
    git-repo-init --clone-only git@github.com:user/repo.git

    # Initialize only in specific directory
    git-repo-init --init-only /path/to/existing/repo

    # Clone to custom path with full setup
    git-repo-init git@gitlab.com:user/repo.git /custom/path

ENVIRONMENT:
    DEBUG_VCS=1       Enable debug logging

CONFIGURATION KEYS:
    mappings.*                           - Host to directory acronym mappings
    accounts.*.user.name                - Account-specific git user name
    accounts.*.user.email               - Account-specific git user email
    accounts.*.protocol                 - Preferred protocol (ssh/https)
    accounts.*.host-alias               - SSH host alias mapping (legacy)
    accounts.*.init.defaultBranch            - Account-specific default branch
    accounts.*.init.create-gh-pages          - Account-specific GitHub Pages setting
    accounts.*.init.create-user-branch       - Account-specific user branch setting
    accounts.*.init.create-environment-branches - Account-specific env branch creation toggle
    accounts.*.init.environment-branches     - Account-specific environment branches
    accounts.*.init.user-branch-pattern - Account-specific user branch pattern
    accounts.*.init.archive-tag-pattern - Account-specific archive tag pattern
    accounts.*.paths.base               - Account-specific base project directory
    accounts.*.paths.pattern            - Account-specific directory structure pattern
    ssh-aliases."host/namespace"        - Namespace-specific SSH aliases
    ssh-aliases.defaults.*              - Default host-only SSH aliases

EOF
}

# Parse command line arguments
parse_arguments() {
    local clone_only=false
    local init_only=false
    local remote_url=""
    local target_dir=""
    local cli_user=""
    local cli_email=""
    local dry_run=false

    while [[ $# -gt 0 ]]; do
        case $1 in
            -c|--clone-only)
                clone_only=true
                shift
                ;;
            -i|--init-only)
                init_only=true
                shift
                ;;
            -u|--user)
                cli_user="$2"
                shift; shift
                ;;
            -e|--email)
                cli_email="$2"
                shift; shift
                ;;
            -n|--dry-run)
                dry_run=true
                shift
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            --usage)
                show_usage
                exit 0
                ;;
            -*)
                vcs_log_error "Unknown option: $1"
                show_help
                exit 1
                ;;
            *)
                if [[ -z "$remote_url" ]]; then
                    remote_url="$1"
                elif [[ -z "$target_dir" ]]; then
                    target_dir="$1"
                else
                    vcs_log_error "Too many arguments: $1"
                    show_help
                    exit 1
                fi
                shift
                ;;
        esac
    done

    # Validate argument combinations
    if [[ "$clone_only" == true && "$init_only" == true ]]; then
        vcs_log_error "Cannot specify both --clone-only and --init-only"
        exit 1
    fi

    if [[ "$clone_only" == true && -z "$remote_url" ]]; then
        vcs_log_error "--clone-only requires a remote URL"
        exit 1
    fi

    # Export parsed values for main function
    export PARSED_CLONE_ONLY="$clone_only"
    export PARSED_INIT_ONLY="$init_only"
    export PARSED_REMOTE_URL="$remote_url"
    export PARSED_TARGET_DIR="$target_dir"
    export PARSED_CLI_USER="$cli_user"
    export PARSED_CLI_EMAIL="$cli_email"
    export PARSED_DRY_RUN="$dry_run"
}

# Parse arguments and call main
parse_arguments "$@"
main "$PARSED_REMOTE_URL" "$PARSED_TARGET_DIR" "$PARSED_CLONE_ONLY" "$PARSED_INIT_ONLY" "$PARSED_CLI_USER" "$PARSED_CLI_EMAIL" "$PARSED_DRY_RUN"
