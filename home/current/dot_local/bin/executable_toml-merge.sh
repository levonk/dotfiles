#!/usr/bin/env bash
# =====================================================================
# TOML Merge Tool
# Managed by chezmoi | https://github.com/levonk/dotfiles
#
# Purpose:
#   - General-purpose TOML file parsing and merging utility
#   - Extract values from TOML files with hierarchical fallback
#   - Support for nested keys and section-based configuration
#   - Environment variable expansion and default values
#
# Usage:
#   toml-merge.sh get <file1> [file2...] <key> [default]
#   toml-merge.sh list <file1> [file2...] [section]
#   toml-merge.sh validate <file1> [file2...]
#
# Examples:
#   toml-merge.sh get config.toml user.toml "accounts.github.user.name" "default-user"
#   toml-merge.sh list config.toml user.toml accounts.github
#   toml-merge.sh validate config.toml
#
# Security: No sensitive data processing, safe for all environments
# =====================================================================

set -euo pipefail

# =============================================================================
# Configuration Variables
# =============================================================================
SCRIPT_NAME="$(basename "$0")"
VERSION="1.0.0"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Debug mode
DEBUG_TOML_MERGE="${DEBUG_TOML_MERGE:-0}"

# =============================================================================
# Logging Functions
# =============================================================================
log_info() {
    echo -e "${BLUE}[TOML-INFO]${NC} $1" >&2
}

log_success() {
    echo -e "${GREEN}[TOML-SUCCESS]${NC} $1" >&2
}

log_warning() {
    echo -e "${YELLOW}[TOML-WARNING]${NC} $1" >&2
}

log_error() {
    echo -e "${RED}[TOML-ERROR]${NC} $1" >&2
}

log_debug() {
    [[ "$DEBUG_TOML_MERGE" == "1" ]] && echo -e "${CYAN}[TOML-DEBUG]${NC} $1" >&2
    return 0
}

# =============================================================================
# TOML Parsing Functions
# =============================================================================

# Parse a single value from a TOML file
# Usage: parse_toml_value <file> <key> [default]
parse_toml_value() {
    local file="$1"
    local key="$2"
    local default="${3:-}"

    if [[ ! -f "$file" ]]; then
        log_debug "File not found: $file"
        echo "$default"
        return
    fi

    log_debug "Parsing key '$key' from file '$file'"

    # Handle nested keys like accounts.github.user.email
    local section=""
    local target_section=""
    local target_key=""

    # Parse nested key structure
    if [[ "$key" =~ ^([^.]+)\.(.+)\.([^.]+)$ ]]; then
        # Three-level nesting: section.subsection.key
        target_section="${BASH_REMATCH[1]}.${BASH_REMATCH[2]}"
        target_key="${BASH_REMATCH[3]}"
    elif [[ "$key" =~ ^([^.]+)\.([^.]+)$ ]]; then
        # Two-level nesting: section.key
        target_section="${BASH_REMATCH[1]}"
        target_key="${BASH_REMATCH[2]}"
    else
        # Top-level key
        target_section=""
        target_key="$key"
    fi

    log_debug "Target section: '$target_section', target key: '$target_key'"

    local in_target_section=false
    local value=""

    while IFS= read -r line; do
        # Skip comments and empty lines
        [[ "$line" =~ ^[[:space:]]*# ]] && continue
        [[ "$line" =~ ^[[:space:]]*$ ]] && continue

        # Check for section headers
        if [[ "$line" =~ ^\[([^\]]+)\] ]]; then
            section="${BASH_REMATCH[1]}"
            log_debug "Found section: [$section]"

            if [[ "$section" == "$target_section" ]]; then
                in_target_section=true
                log_debug "Entered target section: [$target_section]"
            else
                in_target_section=false
            fi
            continue
        fi

        # Parse key-value pairs
        if [[ "$line" =~ ^[[:space:]]*([^=]+)[[:space:]]*=[[:space:]]*(.+)$ ]]; then
            local current_key="${BASH_REMATCH[1]// /}"  # Remove spaces
            local current_value="${BASH_REMATCH[2]}"

            # Remove quotes from value
            current_value="${current_value#\"}"
            current_value="${current_value%\"}"
            current_value="${current_value#\'}"
            current_value="${current_value%\'}"

            log_debug "Found key-value: '$current_key' = '$current_value'"

            # Check if this is our target key
            if [[ -z "$target_section" && "$current_key" == "$target_key" ]] || \
               [[ "$in_target_section" == true && "$current_key" == "$target_key" ]]; then
                value="$current_value"
                log_debug "Match found: '$key' = '$value'"
                break
            fi
        fi
    done < "$file"

    echo "${value:-$default}"
}

# Get value from multiple TOML files with priority order
# Usage: get_merged_value <key> <default> <file1> [file2...]
get_merged_value() {
    local key="$1"
    local default="$2"
    shift 2
    local files=("$@")

    log_debug "Getting merged value for key '$key' with default '$default'"
    log_debug "Files to check (in priority order): ${files[*]}"

    # Try each file in order (first file has highest priority)
    for file in "${files[@]}"; do
        if [[ -f "$file" ]]; then
            local value
            value=$(parse_toml_value "$file" "$key" "")
            if [[ -n "$value" ]]; then
                log_debug "Found value '$value' in file '$file'"
                echo "$value"
                return 0
            fi
        else
            log_debug "File not found: $file"
        fi
    done

    log_debug "No value found, using default: '$default'"
    echo "$default"
}

# List all keys in a section from multiple TOML files
# Usage: list_section_keys <section> <file1> [file2...]
list_section_keys() {
    local section="$1"
    shift
    local files=("$@")

    log_debug "Listing keys in section '$section' from files: ${files[*]}"

    declare -A keys_found

    for file in "${files[@]}"; do
        if [[ ! -f "$file" ]]; then
            log_debug "File not found: $file"
            continue
        fi

        local in_target_section=false
        local current_section=""

        while IFS= read -r line; do
            # Skip comments and empty lines
            [[ "$line" =~ ^[[:space:]]*# ]] && continue
            [[ "$line" =~ ^[[:space:]]*$ ]] && continue

            # Check for section headers
            if [[ "$line" =~ ^\[([^\]]+)\] ]]; then
                current_section="${BASH_REMATCH[1]}"
                if [[ "$current_section" == "$section" ]]; then
                    in_target_section=true
                else
                    in_target_section=false
                fi
                continue
            fi

            # Parse key-value pairs in target section
            if [[ "$in_target_section" == true && "$line" =~ ^[[:space:]]*([^=]+)[[:space:]]*=[[:space:]]*(.+)$ ]]; then
                local key="${BASH_REMATCH[1]// /}"
                local value="${BASH_REMATCH[2]}"

                # Remove quotes from value
                value="${value#\"}"
                value="${value%\"}"
                value="${value#\'}"
                value="${value%\'}"

                keys_found["$key"]="$value"
                log_debug "Found key in section [$section]: $key = $value"
            fi
        done < "$file"
    done

    # Output all found keys
    for key in "${!keys_found[@]}"; do
        echo "$key=${keys_found[$key]}"
    done
}

# Validate TOML file syntax
# Usage: validate_toml_file <file>
validate_toml_file() {
    local file="$1"

    if [[ ! -f "$file" ]]; then
        log_error "File not found: $file"
        return 1
    fi

    log_debug "Validating TOML file: $file"

    local line_number=0
    local current_section=""
    local errors=0

    while IFS= read -r line; do
        ((line_number++))

        # Skip comments and empty lines
        [[ "$line" =~ ^[[:space:]]*# ]] && continue
        [[ "$line" =~ ^[[:space:]]*$ ]] && continue

        # Check section headers
        if [[ "$line" =~ ^\[([^\]]+)\] ]]; then
            current_section="${BASH_REMATCH[1]}"
            log_debug "Line $line_number: Section [$current_section]"
            continue
        fi

        # Check key-value pairs
        if [[ "$line" =~ ^[[:space:]]*([^=]+)[[:space:]]*=[[:space:]]*(.+)$ ]]; then
            local key="${BASH_REMATCH[1]// /}"
            local value="${BASH_REMATCH[2]}"
            log_debug "Line $line_number: Key '$key' = '$value'"
            continue
        fi

        # If we get here, the line doesn't match expected patterns
        log_error "Line $line_number: Invalid syntax: $line"
        ((errors++))
    done < "$file"

    if [[ $errors -eq 0 ]]; then
        log_success "TOML file is valid: $file"
        return 0
    else
        log_error "TOML file has $errors syntax errors: $file"
        return 1
    fi
}

# =============================================================================
# Command Line Interface
# =============================================================================

show_help() {
    cat << EOF
${SCRIPT_NAME} v${VERSION} - General-purpose TOML merge tool

USAGE:
    ${SCRIPT_NAME} get <file1> [file2...] <key> [default]
    ${SCRIPT_NAME} list <file1> [file2...] [section]
    ${SCRIPT_NAME} validate <file1> [file2...]
    ${SCRIPT_NAME} --help | -h
    ${SCRIPT_NAME} --version | -v

COMMANDS:
    get         Get value for a key from TOML files (first file has priority)
    list        List all keys in a section from TOML files
    validate    Validate TOML file syntax

OPTIONS:
    --help, -h      Show this help message
    --version, -v   Show version information

EXAMPLES:
    # Get a value with fallback
    ${SCRIPT_NAME} get user.toml config.toml "accounts.github.user.name" "default-user"

    # List all keys in a section
    ${SCRIPT_NAME} list config.toml accounts.github

    # Validate TOML files
    ${SCRIPT_NAME} validate config.toml user.toml

ENVIRONMENT VARIABLES:
    DEBUG_TOML_MERGE=1    Enable debug output

For more information, see: https://github.com/levonk/dotfiles
EOF
}

show_version() {
    echo "${SCRIPT_NAME} v${VERSION}"
}

# Main command dispatcher
main() {
    if [[ $# -eq 0 ]]; then
        show_help
        exit 1
    fi

    case "$1" in
        get)
            shift
            if [[ $# -lt 3 ]]; then
                log_error "Usage: $SCRIPT_NAME get <file1> [file2...] <key> [default]"
                exit 1
            fi

            # Extract key and default from the end of arguments
            local key="${@: -2:1}"
            local default="${@: -1}"

            # Check if last argument is actually a default or another key
            if [[ $# -eq 3 ]]; then
                # Only 3 args: file, key, default
                local files=("$1")
                key="$2"
                default="$3"
            else
                # Multiple files, extract files from beginning
                local files=("${@:1:$(($# - 2))}")
                key="${@: -2:1}"
                default="${@: -1}"
            fi

            get_merged_value "$key" "$default" "${files[@]}"
            ;;
        list)
            shift
            if [[ $# -lt 1 ]]; then
                log_error "Usage: $SCRIPT_NAME list <file1> [file2...] [section]"
                exit 1
            fi

            # Extract section from the end if provided
            local section=""
            local files=("$@")

            # If last argument doesn't end with .toml, it's probably a section
            if [[ "${@: -1}" != *.toml ]]; then
                section="${@: -1}"
                files=("${@:1:$(($# - 1))}")
            fi

            list_section_keys "$section" "${files[@]}"
            ;;
        validate)
            shift
            if [[ $# -lt 1 ]]; then
                log_error "Usage: $SCRIPT_NAME validate <file1> [file2...]"
                exit 1
            fi

            local exit_code=0
            for file in "$@"; do
                if ! validate_toml_file "$file"; then
                    exit_code=1
                fi
            done
            exit $exit_code
            ;;
        --help|-h)
            show_help
            ;;
        --version|-v)
            show_version
            ;;
        *)
            log_error "Unknown command: $1"
            log_error "Use '$SCRIPT_NAME --help' for usage information"
            exit 1
            ;;
    esac
}

# =============================================================================
# Script Entry Point
# =============================================================================
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # Script is being executed directly
    main "$@"
else
    # Script is being sourced, export functions for library use
    export -f parse_toml_value
    export -f get_merged_value
    export -f list_section_keys
    export -f validate_toml_file
    log_debug "TOML merge functions loaded as library"
fi
