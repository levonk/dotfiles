# =====================================================================
# Universal Shared RC (shell-neutral)
# Managed by chezmoi | https://github.com/levonk/dotfiles
#
# Purpose:
#   - Provides all logic, aliases, and env setup shared by all shells (Bash, Zsh, etc.)
#   - Sourced by all shell-specific rc files for DRY modularization
#
# Shell Support:
#   - Safe for POSIX shells (Bash, Zsh, Dash, etc.)
#   - Extensible: add more shared logic as needed
#
# Security: No sensitive data, no unsafe calls
# Compliance: See LICENSE and admin/licenses.md
# =====================================================================

# Define base directories for sourcing
SHELLS_SHARED_DIR="$HOME/.config/shells/shared"
ENV_DIR="$SHELLS_SHARED_DIR/env"
UTIL_DIR="$SHELLS_SHARED_DIR/util"
ALIASES_DIR="$SHELLS_SHARED_DIR/aliases"

# Source all files in the env/ directory with safety checks
if [ -d "$ENV_DIR" ]; then
    for config_file in "$ENV_DIR/"*; do
        # Skip if no files match the glob pattern
        [ -e "$config_file" ] || continue
        
        if [ -r "$config_file" ] && [ -f "$config_file" ]; then
            # Basic safety check: ensure it's a shell script
            case "$config_file" in
                *.sh|*.bash|*.zsh|*[!.]*) 
                    . "$config_file" || {
                        echo "Warning: Failed to source $config_file" >&2
                    }
                    ;;
                *)
                    echo "Warning: Skipping non-shell file: $config_file" >&2
                    ;;
            esac
        fi
    done
else
    echo "Warning: env directory not found: $ENV_DIR" >&2
fi

# Source all files in the util/ directory with safety checks
if [ -d "$UTIL_DIR" ]; then
    for util_file in "$UTIL_DIR/"*; do
        # Skip if no files match the glob pattern
        [ -e "$util_file" ] || continue
        
        if [ -r "$util_file" ] && [ -f "$util_file" ]; then
            # Basic safety check: ensure it's a shell script
            case "$util_file" in
                *.sh|*.bash|*.zsh|*[!.]*) 
                    . "$util_file" || {
                        echo "Warning: Failed to source $util_file" >&2
                    }
                    ;;
                *)
                    echo "Warning: Skipping non-shell file: $util_file" >&2
                    ;;
            esac
        fi
    done
else
    echo "Warning: util directory not found: $UTIL_DIR" >&2
fi

# Source all files in the aliases/ directory with safety checks
if [ -d "$ALIASES_DIR" ]; then
    for alias_file in "$ALIASES_DIR/"*; do
        # Skip if no files match the glob pattern
        [ -e "$alias_file" ] || continue
        
        if [ -r "$alias_file" ] && [ -f "$alias_file" ]; then
            # Basic safety check: ensure it's a shell script
            case "$alias_file" in
                *.sh|*.bash|*.zsh|*[!.]*) 
                    . "$alias_file" || {
                        echo "Warning: Failed to source $alias_file" >&2
                    }
                    ;;
                *)
                    echo "Warning: Skipping non-shell file: $alias_file" >&2
                    ;;
            esac
        fi
    done
else
    echo "Warning: aliases directory not found: $ALIASES_DIR" >&2
fi

# Export for compliance and test detection
export DOTFILES_SHARED_RC_LOADED=1
