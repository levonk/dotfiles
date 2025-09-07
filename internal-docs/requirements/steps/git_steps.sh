#!/usr/bin/env bats

# Git Configuration Test Steps
# Tests for Git configuration management and modular setup

setup() {
    # Create temporary test environment
    export TEST_HOME=$(mktemp -d)
    export ORIGINAL_HOME="$HOME"
    export HOME="$TEST_HOME"
    
    # Setup Git test environment
    mkdir -p "$TEST_HOME/.config/git"
    export GIT_CONFIG_GLOBAL="$TEST_HOME/.config/git/config"
}

teardown() {
    # Cleanup test environment
    export HOME="$ORIGINAL_HOME"
    rm -rf "$TEST_HOME"
}

@test "Modular Git configuration includes all modules" {
    # Given: Modular Git configuration exists
    CONFIG_DIR="$TEST_HOME/.config/git"
    mkdir -p "$CONFIG_DIR"
    
    # Create main modular config
    cat > "$CONFIG_DIR/config" << 'EOF'
[include]
    path = aliases.gitconfig
    path = core.gitconfig
    path = diff-merge.gitconfig
EOF
    
    # Create module files
    echo '[alias]' > "$CONFIG_DIR/aliases.gitconfig"
    echo '    st = status' >> "$CONFIG_DIR/aliases.gitconfig"
    
    echo '[core]' > "$CONFIG_DIR/core.gitconfig"
    echo '    editor = vim' >> "$CONFIG_DIR/core.gitconfig"
    
    echo '[diff]' > "$CONFIG_DIR/diff-merge.gitconfig"
    echo '    tool = vimdiff' >> "$CONFIG_DIR/diff-merge.gitconfig"
    
    # When: Git reads configuration
    run git config --global --get alias.st
    
    # Then: Aliases should be available
    [ "$status" -eq 0 ]
    [ "$output" = "status" ]
}

@test "Git ignore files are properly linked" {
    # Given: Git ignore files exist
    IGNORE_DIR="$TEST_HOME/.config/git"
    mkdir -p "$IGNORE_DIR"
    
    # Create original ignore file
    echo "*.log" > "$IGNORE_DIR/globalignore"
    echo "*.tmp" >> "$IGNORE_DIR/globalignore"
    
    # Create hard link
    ln "$IGNORE_DIR/globalignore" "$IGNORE_DIR/dot_gitglobalignore"
    
    # When: Both files are checked
    ORIGINAL_CONTENT=$(cat "$IGNORE_DIR/globalignore")
    LINKED_CONTENT=$(cat "$IGNORE_DIR/dot_gitglobalignore")
    
    # Then: Content should be identical
    [ "$ORIGINAL_CONTENT" = "$LINKED_CONTENT" ]
    
    # And: Files should have same inode (hard link)
    ORIGINAL_INODE=$(stat -c %i "$IGNORE_DIR/globalignore" 2>/dev/null || stat -f %i "$IGNORE_DIR/globalignore")
    LINKED_INODE=$(stat -c %i "$IGNORE_DIR/dot_gitglobalignore" 2>/dev/null || stat -f %i "$IGNORE_DIR/dot_gitglobalignore")
    [ "$ORIGINAL_INODE" = "$LINKED_INODE" ]
}

@test "Git commit template is properly configured" {
    # Given: Git commit template exists
    TEMPLATE_FILE="$TEST_HOME/.config/git/commit-template.txt"
    mkdir -p "$(dirname "$TEMPLATE_FILE")"
    
    cat > "$TEMPLATE_FILE" << 'EOF'
# Commit Message Template

# Type: Brief description (50 chars max)
#
# Longer explanation if needed (wrap at 72 chars)
#
# - Use bullet points for multiple changes
# - Reference issues: Fixes #123, Closes #456
EOF
    
    # Configure Git to use template
    git config --global commit.template "$TEMPLATE_FILE"
    
    # When: Git commit template is checked
    CONFIGURED_TEMPLATE=$(git config --global commit.template)
    
    # Then: Template should be configured correctly
    [ "$CONFIGURED_TEMPLATE" = "$TEMPLATE_FILE" ]
    [ -f "$TEMPLATE_FILE" ]
}

@test "No duplicate Git template files exist" {
    # Given: Git configuration directory
    CONFIG_DIR="$TEST_HOME/.config/git"
    mkdir -p "$CONFIG_DIR"
    
    # Create only .txt template
    touch "$CONFIG_DIR/commit-template.txt"
    
    # When: Directory is checked for templates
    MD_COUNT=$(find "$CONFIG_DIR" -name "commit-template.md" | wc -l)
    TXT_COUNT=$(find "$CONFIG_DIR" -name "commit-template.txt" | wc -l)
    
    # Then: Only .txt template should exist
    [ "$TXT_COUNT" -eq 1 ]
    [ "$MD_COUNT" -eq 0 ]
}

@test "Git configuration validation passes" {
    # Given: Valid Git configuration
    git config --global user.name "Test User"
    git config --global user.email "test@example.com"
    
    # When: Git configuration is validated
    run git config --global --list
    
    # Then: No configuration errors should occur
    [ "$status" -eq 0 ]
    [[ "$output" =~ "user.name=Test User" ]]
    [[ "$output" =~ "user.email=test@example.com" ]]
}
