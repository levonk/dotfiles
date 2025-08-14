#!/bin/bash
# =====================================================================
# Git Repository Initialization Script
# Managed by chezmoi | https://github.com/levonk/dotfiles
#
# Purpose:
#   - Initialize git repository with preferred branch structure
#   - Create archive tags for root commit and pre-branch state
#   - Set up environment branches and user-specific development branch
#   - Create clean GitHub Pages branch for documentation
#   - Push all branches and tags to remote
#
# Usage: git-repo-init [remote-url]
# Example: git-repo-init git@github.com:user/repo.git
#
# Security: No sensitive data, safe for all environments
# Compliance: See LICENSE and admin/licenses.md
# =====================================================================

set -euo pipefail  # Exit on error, undefined vars, pipe failures

# Configuration
CURRENT_YEAR=$(date +%Y)
DEFAULT_BRANCH="main"
USER="${USER:-${USERNAME:-$(whoami)}}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
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
    if ! check_git_repo; then
        git init
        log_success "Git repository initialized"
        
        # Create initial commit if no commits exist
        if ! git rev-parse HEAD >/dev/null 2>&1; then
            # Create a README if it doesn't exist
            if [[ ! -f README.md ]]; then
                cat > README.md << EOF
# $(basename "$(pwd)")

Repository initialized with git-repo-init script.

## Branch Structure

- \`main\` - Main development branch
- \`env/prod\` - Production environment
- \`env/stage\` - Staging environment  
- \`env/dev\` - Development environment
- \`u/$USER/env/dev\` - Personal development branch
- \`gh_pages\` - GitHub Pages documentation (if needed)

## Archive Tags

- \`tag/archive/$CURRENT_YEAR/git-root-node\` - Root commit
- \`tag/archive/$CURRENT_YEAR/pre-init-branches\` - State before branch creation
EOF
            fi
            
            git add README.md
            git commit -m "feat: initial repository setup

Initialize repository with standard branch structure and documentation.
Created by git-repo-init script on $(date -Iseconds)."
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
        git tag -a "$tag_name" "$root_commit" -m "Archive tag for git root node

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
        git tag -a "$tag_name" HEAD -m "Archive tag before branch initialization

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
        git checkout "$gh_pages_branch"
        
        # Remove all files if any exist
        if [[ -n "$(git ls-files)" ]]; then
            git rm -rf .
            git commit -m "chore: clean GitHub Pages branch

Remove all files to prepare for documentation.
Cleaned by git-repo-init script on $(date -Iseconds)." || true
        fi
    else
        log_info "Creating clean GitHub Pages branch..."
        git checkout --orphan "$gh_pages_branch"
        git rm -rf . 2>/dev/null || true
        
        # Create basic index.html for GitHub Pages
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
        
        git add index.html
        git commit -m "feat: initialize GitHub Pages

Create basic GitHub Pages site structure.
Created by git-repo-init script on $(date -Iseconds)."
    fi
    
    log_success "GitHub Pages branch ready"
}

# Create environment branches
create_environment_branches() {
    local branches=("env/prod" "env/stage" "env/dev" "u/$USER/env/dev")
    
    # Switch back to main branch
    git checkout "$DEFAULT_BRANCH"
    
    for branch in "${branches[@]}"; do
        if git show-ref --verify --quiet "refs/heads/$branch"; then
            log_warning "Branch $branch already exists"
        else
            git checkout -b "$branch"
            log_success "Created branch: $branch"
            git checkout "$DEFAULT_BRANCH"
        fi
    done
}

# Set up remote and push everything
setup_remote_and_push() {
    local remote_url="$1"
    
    if [[ -n "$remote_url" ]]; then
        # Add remote if it doesn't exist
        if ! git remote get-url origin >/dev/null 2>&1; then
            git remote add origin "$remote_url"
            log_success "Added remote origin: $remote_url"
        else
            log_info "Remote origin already exists: $(git remote get-url origin)"
        fi
        
        # Push all branches
        log_info "Pushing all branches to remote..."
        git push -u origin --all
        
        # Push all tags
        log_info "Pushing all tags to remote..."
        git push origin --tags
        
        log_success "All branches and tags pushed to remote"
    else
        log_warning "No remote URL provided, skipping remote setup"
        log_info "To add remote later: git remote add origin <url>"
        log_info "To push: git push -u origin --all && git push origin --tags"
    fi
}

# Switch to user development branch
switch_to_user_branch() {
    local user_branch="u/$USER/env/dev"
    git checkout "$user_branch"
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

# Main execution
main() {
    local remote_url="${1:-}"
    
    log_info "Starting git repository initialization..."
    log_info "User: $USER"
    log_info "Year: $CURRENT_YEAR"
    [[ -n "$remote_url" ]] && log_info "Remote URL: $remote_url"
    echo
    
    # Execute initialization steps
    init_git_repo
    create_root_tag
    create_pre_branches_tag
    setup_gh_pages
    create_environment_branches
    
    # Setup remote and push if URL provided
    if [[ -n "$remote_url" ]]; then
        setup_remote_and_push "$remote_url"
    fi
    
    # Switch to user development branch
    switch_to_user_branch
    
    # Show final status
    show_final_status
}

# Help function
show_help() {
    cat << EOF
Git Repository Initialization Script

USAGE:
    git-repo-init [remote-url]

DESCRIPTION:
    Initializes a git repository with a standardized branch structure,
    archive tags, and GitHub Pages setup.

FEATURES:
    • Creates git repository if not already in one
    • Tags root commit as tag/archive/$CURRENT_YEAR/git-root-node
    • Tags current state as tag/archive/$CURRENT_YEAR/pre-init-branches
    • Creates clean gh_pages branch for GitHub Pages
    • Creates environment branches: env/prod, env/stage, env/dev
    • Creates user development branch: u/$USER/env/dev
    • Pushes all branches and tags to remote (if URL provided)
    • Switches to user development branch

EXAMPLES:
    git-repo-init
    git-repo-init git@github.com:user/repo.git
    git-repo-init https://github.com/user/repo.git

EOF
}

# Parse command line arguments
case "${1:-}" in
    -h|--help)
        show_help
        exit 0
        ;;
    *)
        main "$@"
        ;;
esac
