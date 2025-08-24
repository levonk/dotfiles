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

# Define base directories for sourcing (XDG compliant)
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
SHELLS_SHARED_DIR="$XDG_CONFIG_HOME/shells/shared"
ENV_DIR="$SHELLS_SHARED_DIR/env"
UTIL_DIR="$SHELLS_SHARED_DIR/util"
ALIASES_DIR="$SHELLS_SHARED_DIR/aliases"

# Source all files in the env/ directory with safety checks (safe for empty dirs)
if [ -d "$ENV_DIR" ]; then
    find "$ENV_DIR" -maxdepth 1 -type f \( -name "*.sh" -o -name "*.bash" -o -name "*.zsh" \) 2>/dev/null | while IFS= read -r config_file; do
        if [ -r "$config_file" ] && [ -f "$config_file" ]; then
            . "$config_file" || {
                echo "Warning: Failed to source $config_file" >&2
            }
        fi
    done
else
    echo "Warning: env directory not found: $ENV_DIR" >&2
fi

# Source all files in the util/ directory with safety checks (safe for empty dirs)
if [ -d "$UTIL_DIR" ]; then
    find "$UTIL_DIR" -maxdepth 1 -type f \( -name "*.sh" -o -name "*.bash" -o -name "*.zsh" \) 2>/dev/null | while IFS= read -r util_file; do
        if [ -r "$util_file" ] && [ -f "$util_file" ]; then
            . "$util_file" || {
                echo "Warning: Failed to source $util_file" >&2
            }
        fi
    done
else
    echo "Warning: util directory not found: $UTIL_DIR" >&2
fi

# Source all files in the aliases/ directory with safety checks (safe for empty dirs)
if [ -d "$ALIASES_DIR" ]; then
    find "$ALIASES_DIR" -maxdepth 1 -type f \( -name "*.sh" -o -name "*.bash" -o -name "*.zsh" \) 2>/dev/null | while IFS= read -r alias_file; do
        if [ -r "$alias_file" ] && [ -f "$alias_file" ]; then
            . "$alias_file" || {
                echo "Warning: Failed to source $alias_file" >&2
            }
        fi
    done
else
    echo "Warning: aliases directory not found: $ALIASES_DIR" >&2
fi

# Export for compliance and test detection
export DOTFILES_SHARED_RC_LOADED=1

