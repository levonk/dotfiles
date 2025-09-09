# shellcheck shell=sh
#!/bin/bash
if [[ "" == "bash" ]]; then
  echo "ERROR: This script must be sourced, not executed."
  exit 1
fi
#!/bin/bash
# =====================================================================
# Platform Detection Utility
# Managed by chezmoi | https://github.com/levonk/dotfiles
#
# Purpose:
#   - Cross-platform detection for Windows/Unix systems
#   - Path handling utilities for different platforms
#   - Shell availability detection
#   - Tool availability checks with graceful fallbacks
#
# Shell Support:
#   - Safe for POSIX shells (Bash, Zsh, Dash, etc.)
#   - Works on Windows (Git Bash, WSL), macOS, Linux
#
# Security: No sensitive data, no unsafe calls
# Compliance: See LICENSE and admin/licenses.md
# =====================================================================

# Platform detection variables
DOTFILES_PLATFORM=""
DOTFILES_IS_WINDOWS=""
DOTFILES_IS_WSL=""
DOTFILES_IS_MACOS=""
DOTFILES_IS_LINUX=""
DOTFILES_PATH_SEPARATOR=""

# Detect current platform
detect_platform() {
    # Reset variables
    DOTFILES_PLATFORM=""
    DOTFILES_IS_WINDOWS=""
    DOTFILES_IS_WSL=""
    DOTFILES_IS_MACOS=""
    DOTFILES_IS_LINUX=""
    
    # Check for Windows (including Git Bash, MSYS2, Cygwin)
    if [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]] || [[ "$OSTYPE" == "win32" ]]; then
        DOTFILES_PLATFORM="windows"
        DOTFILES_IS_WINDOWS="true"
        DOTFILES_PATH_SEPARATOR=";"
    # Check for WSL (Windows Subsystem for Linux)
    elif [[ -n "${WSL_DISTRO_NAME:-}" ]] || [[ "$(uname -r)" == *microsoft* ]] || [[ "$(uname -r)" == *Microsoft* ]]; then
        DOTFILES_PLATFORM="wsl"
        DOTFILES_IS_WSL="true"
        DOTFILES_PATH_SEPARATOR=":"
    # Check for macOS
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        DOTFILES_PLATFORM="macos"
        DOTFILES_IS_MACOS="true"
        DOTFILES_PATH_SEPARATOR=":"
    # Check for Linux
    elif [[ "$OSTYPE" == "linux-gnu"* ]] || [[ "$(uname)" == "Linux" ]]; then
        DOTFILES_PLATFORM="linux"
        DOTFILES_IS_LINUX="true"
        DOTFILES_PATH_SEPARATOR=":"
    # Fallback detection
    else
        case "$(uname -s)" in
            CYGWIN*|MINGW*|MSYS*)
                DOTFILES_PLATFORM="windows"
                DOTFILES_IS_WINDOWS="true"
                DOTFILES_PATH_SEPARATOR=";"
                ;;
            Darwin)
                DOTFILES_PLATFORM="macos"
                DOTFILES_IS_MACOS="true"
                DOTFILES_PATH_SEPARATOR=":"
                ;;
            Linux)
                DOTFILES_PLATFORM="linux"
                DOTFILES_IS_LINUX="true"
                DOTFILES_PATH_SEPARATOR=":"
                ;;
            *)
                DOTFILES_PLATFORM="unknown"
                DOTFILES_PATH_SEPARATOR=":"
                echo "Warning: Unknown platform detected: $(uname -s)" >&2
                ;;
        esac
    fi
    
    # Export variables for use by other scripts
    export DOTFILES_PLATFORM DOTFILES_IS_WINDOWS DOTFILES_IS_WSL DOTFILES_IS_MACOS DOTFILES_IS_LINUX DOTFILES_PATH_SEPARATOR
}

# Convert Unix path to Windows path (for Windows/WSL interop)
unix_to_windows_path() {
    local unix_path="$1"
    if [[ "$DOTFILES_IS_WSL" == "true" ]]; then
        # Use wslpath if available
        if command -v wslpath >/dev/null 2>&1; then
            wslpath -w "$unix_path" 2>/dev/null || echo "$unix_path"
        else
            # Fallback: basic conversion
            echo "$unix_path" | sed 's|^/mnt/\([a-z]\)/|\1:/|' | sed 's|/|\\|g'
        fi
    elif [[ "$DOTFILES_IS_WINDOWS" == "true" ]]; then
        # Convert /c/path to C:\path format
        echo "$unix_path" | sed 's|^/\([a-z]\)/|\1:/|' | sed 's|/|\\|g'
    else
        echo "$unix_path"
    fi
}

# Convert Windows path to Unix path
windows_to_unix_path() {
    local windows_path="$1"
    if [[ "$DOTFILES_IS_WSL" == "true" ]]; then
        # Use wslpath if available
        if command -v wslpath >/dev/null 2>&1; then
            wslpath -u "$windows_path" 2>/dev/null || echo "$windows_path"
        else
            # Fallback: basic conversion
            echo "$windows_path" | sed 's|^\([A-Za-z]\):|/mnt/\L\1|' | sed 's|\\|/|g'
        fi
    elif [[ "$DOTFILES_IS_WINDOWS" == "true" ]]; then
        # Convert C:\path to /c/path format
        echo "$windows_path" | sed 's|^\([A-Za-z]\):|/\L\1|' | sed 's|\\|/|g'
    else
        echo "$windows_path"
    fi
}

# Normalize path for current platform
normalize_path() {
    local input_path="$1"
    
    # Handle empty input
    [[ -z "$input_path" ]] && return 1
    
    # If on Windows, convert Unix-style paths
    if [[ "$DOTFILES_IS_WINDOWS" == "true" ]] && [[ "$input_path" == /* ]]; then
        unix_to_windows_path "$input_path"
    # If on Unix, convert Windows-style paths
    elif [[ "$DOTFILES_IS_WINDOWS" != "true" ]] && [[ "$input_path" =~ ^[A-Za-z]: ]]; then
        windows_to_unix_path "$input_path"
    else
        echo "$input_path"
    fi
}

# Check if a shell is available
is_shell_available() {
    local shell_name="$1"
    command -v "$shell_name" >/dev/null 2>&1
}

# Check if a tool is available with informative error message
check_tool_availability() {
    local tool_name="$1"
    local description="${2:-$tool_name}"
    
    if command -v "$tool_name" >/dev/null 2>&1; then
        return 0
    else
        echo "Warning: $description ($tool_name) is not available on this system" >&2
        return 1
    fi
}

# Get available shells on the system
get_available_shells() {
    local shells=""
    
    # Check common shells
    for shell in bash zsh fish dash sh; do
        if is_shell_available "$shell"; then
            shells="${shells:+$shells }$shell"
        fi
    done
    
    echo "$shells"
}

# Get shell-specific configuration directory
get_shell_config_dir() {
    local shell_name="$1"
    local base_dir="${XDG_CONFIG_HOME:-$HOME/.config}/shells"
    
    case "$shell_name" in
        bash|zsh|fish|dash)
            echo "$base_dir/$shell_name"
            ;;
        *)
            echo "$base_dir/shared"
            ;;
    esac
}

# Platform-specific PATH handling
add_to_path() {
    local new_path="$1"
    local position="${2:-end}"  # 'start' or 'end'
    
    # Normalize the path for current platform
    new_path=$(normalize_path "$new_path")
    
    # Check if path exists and is a directory
    [[ ! -d "$new_path" ]] && return 1
    
    # Check if already in PATH
    case ":$PATH:" in
        *":$new_path:"*) return 0 ;;
    esac
    
    # Add to PATH
    if [[ "$position" == "start" ]]; then
        PATH="$new_path${DOTFILES_PATH_SEPARATOR}$PATH"
    else
        PATH="$PATH${DOTFILES_PATH_SEPARATOR}$new_path"
    fi
    
    export PATH
}

# Initialize platform detection on source
detect_platform

# Provide platform information functions
get_platform() { echo "$DOTFILES_PLATFORM"; }
is_windows() { [[ "$DOTFILES_IS_WINDOWS" == "true" ]]; }
is_wsl() { [[ "$DOTFILES_IS_WSL" == "true" ]]; }
is_macos() { [[ "$DOTFILES_IS_MACOS" == "true" ]]; }
is_linux() { [[ "$DOTFILES_IS_LINUX" == "true" ]]; }
is_unix() { [[ "$DOTFILES_IS_WINDOWS" != "true" ]]; }

# Debug function to show platform information
show_platform_info() {
    echo "=== Platform Detection Information ===" >&2
    echo "Platform: $DOTFILES_PLATFORM" >&2
    echo "Windows: ${DOTFILES_IS_WINDOWS:-false}" >&2
    echo "WSL: ${DOTFILES_IS_WSL:-false}" >&2
    echo "macOS: ${DOTFILES_IS_MACOS:-false}" >&2
    echo "Linux: ${DOTFILES_IS_LINUX:-false}" >&2
    echo "Path Separator: $DOTFILES_PATH_SEPARATOR" >&2
    echo "Available Shells: $(get_available_shells)" >&2
    echo "OSTYPE: ${OSTYPE:-not set}" >&2
    echo "uname -s: $(uname -s 2>/dev/null || echo 'not available')" >&2
    echo "====================================" >&2
}
