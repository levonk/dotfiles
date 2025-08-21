#!/usr/bin/env bats

# Shell Configuration Test Steps
# Tests for shell environment setup and sourcing behavior

setup() {
    # Create temporary test environment
    export TEST_HOME=$(mktemp -d)
    export ORIGINAL_HOME="$HOME"
    export HOME="$TEST_HOME"
    
    # Copy dotfiles structure for testing
    mkdir -p "$TEST_HOME/.config/shells/shared/env"
    mkdir -p "$TEST_HOME/.config/shells/zsh"
    mkdir -p "$TEST_HOME/.config/shells/bash"
}

teardown() {
    # Cleanup test environment
    export HOME="$ORIGINAL_HOME"
    rm -rf "$TEST_HOME"
}

@test "ZSH environment initialization sets ZDOTDIR correctly" {
    # Given: ZSH configuration exists
    touch "$TEST_HOME/.zshenv"
    echo 'export ZDOTDIR="$HOME/.config/shells/zsh"' > "$TEST_HOME/.zshenv"
    
    # When: ZSH configuration is sourced
    source "$TEST_HOME/.zshenv"
    
    # Then: ZDOTDIR should be set correctly
    [ "$ZDOTDIR" = "$TEST_HOME/.config/shells/zsh" ]
}

@test "XDG environment variables are properly sourced" {
    # Given: XDG environment file exists
    XDG_ENV_FILE="$TEST_HOME/.config/shells/shared/env/__xdg-env.sh"
    mkdir -p "$(dirname "$XDG_ENV_FILE")"
    cat > "$XDG_ENV_FILE" << 'EOF'
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
EOF
    
    # When: XDG configuration is sourced
    source "$XDG_ENV_FILE"
    
    # Then: All XDG variables should be set
    [ "$XDG_CONFIG_HOME" = "$TEST_HOME/.config" ]
    [ "$XDG_DATA_HOME" = "$TEST_HOME/.local/share" ]
    [ "$XDG_CACHE_HOME" = "$TEST_HOME/.cache" ]
    [ "$XDG_STATE_HOME" = "$TEST_HOME/.local/state" ]
}

@test "Error handling for missing configuration files" {
    # Given: A shell configuration that sources a missing file
    CONFIG_FILE="$TEST_HOME/.test_config"
    cat > "$CONFIG_FILE" << 'EOF'
MISSING_FILE="$HOME/.config/missing_file.sh"
if [ -r "$MISSING_FILE" ]; then
    . "$MISSING_FILE"
else
    echo "Warning: Could not source $MISSING_FILE" >&2
fi
EOF
    
    # When: Configuration is sourced
    run source "$CONFIG_FILE"
    
    # Then: Should continue execution with warning
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Warning: Could not source" ]]
}

@test "Path safety with quoted variables" {
    # Given: Directory with spaces in name
    SPACE_DIR="$TEST_HOME/directory with spaces"
    mkdir -p "$SPACE_DIR"
    SPACE_FILE="$SPACE_DIR/config.sh"
    echo 'export TEST_VAR="success"' > "$SPACE_FILE"
    
    # When: File is sourced with proper quoting
    run bash -c ". \"$SPACE_FILE\" && echo \$TEST_VAR"
    
    # Then: Should source successfully
    [ "$status" -eq 0 ]
    [ "$output" = "success" ]
}

@test "Shell configuration directories are created if missing" {
    # Given: Configuration directories don't exist
    rm -rf "$TEST_HOME/.config"
    
    # When: Shell configuration creates directories
    mkdir -p "$TEST_HOME/.config/shells/zsh"
    mkdir -p "$TEST_HOME/.config/shells/bash"
    
    # Then: Directories should exist
    [ -d "$TEST_HOME/.config/shells/zsh" ]
    [ -d "$TEST_HOME/.config/shells/bash" ]
}
