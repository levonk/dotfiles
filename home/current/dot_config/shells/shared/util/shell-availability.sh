#!/usr/bin/env sh
# shellcheck shell=sh
#{{- includeTemplate "dot_config/ai/templates/shell/sourceable.sh.tmpl" (dict "path" .path "name" .name) -}}


# =====================================================================

#!/usr/bin/env bash
# =====================================================================
# Shell Availability and Tool Detection Utility
# Managed by chezmoi | https://github.com/levonk/dotfiles
# Purpose:
#   - Graceful fallbacks for missing shells
#   - Tool availability checks before using modern CLI tools
#   - Informative error messages for missing dependencies
# Shell Support:
#   - Safe for POSIX shells (Bash, Zsh, Dash, etc.)
#   - Works on Windows (Git Bash, WSL), macOS, Linux
# Security: No sensitive data, no unsafe calls
# Compliance: See LICENSE and admin/licenses.md
# =====================================================================

# Shell availability registry
DOTFILES_AVAILABLE_SHELLS=""
DOTFILES_FALLBACK_SHELL=""

# Tool availability cache
declare -A DOTFILES_TOOL_CACHE

# Initialize shell availability detection
detect_available_shells() {
    local shells=""
    local fallback=""

    # Check common shells in order of preference
    for shell in zsh bash fish dash sh; do
        if command -v "$shell" >/dev/null 2>&1; then
            shells="${shells:+$shells }$shell"
            # Set first available shell as fallback
            [[ -z "$fallback" ]] && fallback="$shell"
        fi
    done

    DOTFILES_AVAILABLE_SHELLS="$shells"
    DOTFILES_FALLBACK_SHELL="$fallback"

    # Export for use by other scripts
    export DOTFILES_AVAILABLE_SHELLS DOTFILES_FALLBACK_SHELL
}

# Check if a specific shell is available
is_shell_available() {
    local shell_name="$1"
    [[ -z "$shell_name" ]] && return 1

    # Check in our cached list first
    case " $DOTFILES_AVAILABLE_SHELLS " in
        *" $shell_name "*) return 0 ;;
        *) return 1 ;;
    esac
}

# Get the best available shell for a task
get_best_shell() {
    local preferred_shell="${1:-zsh}"

    # If preferred shell is available, use it
    if is_shell_available "$preferred_shell"; then
        echo "$preferred_shell"
        return 0
    fi

    # Otherwise, use fallback
    if [[ -n "$DOTFILES_FALLBACK_SHELL" ]]; then
        echo "$DOTFILES_FALLBACK_SHELL"
        return 0
    fi

    # Last resort: try to find any shell
    for shell in bash sh dash; do
        if command -v "$shell" >/dev/null 2>&1; then
            echo "$shell"
            return 0
        fi
    done

    echo "sh"  # Ultimate fallback
    return 1
}

# Check tool availability with caching
check_tool_cached() {
    local tool_name="$1"

    # Check cache first
    if [[ -n "${DOTFILES_TOOL_CACHE[$tool_name]:-}" ]]; then
        [[ "${DOTFILES_TOOL_CACHE[$tool_name]}" == "available" ]]
        return $?
    fi

    # Check availability and cache result
    if command -v "$tool_name" >/dev/null 2>&1; then
        DOTFILES_TOOL_CACHE[$tool_name]="available"
        return 0
    else
        DOTFILES_TOOL_CACHE[$tool_name]="unavailable"
        return 1
    fi
}

# Check tool availability with informative error message
require_tool() {
    local tool_name="$1"
    local description="${2:-$tool_name}"
    local install_hint="${3:-}"
    local optional="${4:-false}"

    if check_tool_cached "$tool_name"; then
        return 0
    else
        if [[ "$optional" == "true" ]]; then
            echo "Info: Optional tool '$description' ($tool_name) is not available" >&2
            [[ -n "$install_hint" ]] && echo "Info: Install with: $install_hint" >&2
        else
            echo "Error: Required tool '$description' ($tool_name) is not available" >&2
            [[ -n "$install_hint" ]] && echo "Error: Install with: $install_hint" >&2
        fi
        return 1
    fi
}

# Check multiple tools and provide summary
check_modern_tools() {
    local missing_tools=()
    local optional_missing=()

    # Essential modern tools
    local essential_tools=(
        "git:Git version control:apt install git / brew install git"
        "curl:HTTP client:apt install curl / brew install curl"
        "grep:Text search:built-in"
        "find:File search:built-in"
    )

    # Optional modern tools
    local optional_tools=(
        "rg:ripgrep (fast grep):apt install ripgrep / brew install ripgrep:true"
        "fd:fd-find (fast find):apt install fd-find / brew install fd:true"
        "bat:bat (better cat):apt install bat / brew install bat:true"
        "exa:exa (better ls):apt install exa / brew install exa:true"
        "fzf:fuzzy finder:apt install fzf / brew install fzf:true"
        "jq:JSON processor:apt install jq / brew install jq:true"
        "yq:YAML processor:pip install yq / brew install yq:true"
    )

    # Check essential tools
    for tool_spec in "${essential_tools[@]}"; do
        IFS=':' read -r tool_name description install_hint <<< "$tool_spec"
        if ! require_tool "$tool_name" "$description" "$install_hint" "false"; then
            missing_tools+=("$tool_name")
        fi
    done

    # Check optional tools
    for tool_spec in "${optional_tools[@]}"; do
        IFS=':' read -r tool_name description install_hint optional <<< "$tool_spec"
        if ! require_tool "$tool_name" "$description" "$install_hint" "$optional"; then
            optional_missing+=("$tool_name")
        fi
    done

    # Provide summary
    if [[ ${#missing_tools[@]} -gt 0 ]]; then
        echo "Warning: Missing essential tools: ${missing_tools[*]}" >&2
        echo "Warning: Some functionality may not work properly" >&2
        return 1
    fi

    if [[ ${#optional_missing[@]} -gt 0 ]]; then
        echo "Info: Missing optional tools: ${optional_missing[*]}" >&2
        echo "Info: Consider installing for enhanced functionality" >&2
    fi

    return 0
}

# Safe command execution with fallbacks
safe_command() {
    local primary_cmd="$1"
    local fallback_cmd="$2"
    shift 2
    local args=("$@")

    if check_tool_cached "$primary_cmd"; then
        "$primary_cmd" "${args[@]}"
    elif [[ -n "$fallback_cmd" ]] && check_tool_cached "$fallback_cmd"; then
        echo "Info: Using fallback command '$fallback_cmd' instead of '$primary_cmd'" >&2
        "$fallback_cmd" "${args[@]}"
    else
        echo "Error: Neither '$primary_cmd' nor '$fallback_cmd' are available" >&2
        return 1
    fi
}

# Enhanced grep with fallback
safe_grep() {
    safe_command "rg" "grep" "$@"
}

# Enhanced find with fallback
safe_find() {
    safe_command "fd" "find" "$@"
}

# Enhanced ls with fallback
safe_ls() {
    if check_tool_cached "exa"; then
        exa "$@"
    elif check_tool_cached "ls"; then
        # Use ls with color support if available
        if ls --color=auto >/dev/null 2>&1; then
            ls --color=auto "$@"
        else
            ls "$@"
        fi
    else
        echo "Error: No ls command available" >&2
        return 1
    fi
}

# Enhanced cat with fallback
safe_cat() {
    safe_command "bat" "cat" "$@"
}

# Initialize on source
detect_available_shells

# Provide information functions
get_available_shells() { echo "$DOTFILES_AVAILABLE_SHELLS"; }
get_fallback_shell() { echo "$DOTFILES_FALLBACK_SHELL"; }

# Debug function to show shell and tool availability
show_availability_info() {
    echo "=== Shell and Tool Availability ===" >&2
    echo "Available Shells: $DOTFILES_AVAILABLE_SHELLS" >&2
    echo "Fallback Shell: $DOTFILES_FALLBACK_SHELL" >&2
    echo "Tool Cache:" >&2
    for tool in "${!DOTFILES_TOOL_CACHE[@]}"; do
        echo "  $tool: ${DOTFILES_TOOL_CACHE[$tool]}" >&2
    done
    echo "===================================" >&2
}
