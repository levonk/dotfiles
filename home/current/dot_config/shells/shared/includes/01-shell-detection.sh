#!/usr/bin/env sh
# shellcheck shell=sh

# =============================================================================
# 01-shell-detection.sh
#
# ## Purpose
#
# - Detects the current shell (zsh or bash).
# - Defines shell-specific directory variables (e.g., for aliases, completions).
# - Records these directories for startup debugging.
# =============================================================================

# Detect current shell for shell-specific configurations
CURRENT_SHELL=""
if [ -n "${ZSH_VERSION:-}" ]; then
    CURRENT_SHELL="zsh"
elif [ -n "${BASH_VERSION:-}" ]; then
    CURRENT_SHELL="bash"
else
    # Try to detect from $0 or $SHELL
    case "${0##*/}" in
        bash|*bash) CURRENT_SHELL="bash" ;;
        zsh|*zsh) CURRENT_SHELL="zsh" ;;
        *)
            case "${SHELL##*/}" in
                bash) CURRENT_SHELL="bash" ;;
                zsh) CURRENT_SHELL="zsh" ;;
                *) CURRENT_SHELL="unknown" ;;
            esac
            ;;
    esac
fi

# Define shell-specific directory variables
if [ "$CURRENT_SHELL" != "unknown" ] && [ "$CURRENT_SHELL" != "" ]; then
    SHELL_SPECIFIC_DIR="$SHELLS_BASE_DIR/$CURRENT_SHELL"
    SHELL_ENV_DIR="$SHELL_SPECIFIC_DIR/env"
    # Prefer new 'utils' directory; fall back to legacy 'util' during migration
    if [ -d "$SHELL_SPECIFIC_DIR/utils" ]; then
        SHELL_UTIL_DIR="$SHELL_SPECIFIC_DIR/utils"
    else
        SHELL_UTIL_DIR="$SHELL_SPECIFIC_DIR/util"
    fi
    SHELL_ALIASES_DIR="$SHELL_SPECIFIC_DIR/aliases"
    SHELL_COMPLETIONS_DIR="$SHELL_SPECIFIC_DIR/completions"
    SHELL_PROMPTS_DIR="$SHELL_SPECIFIC_DIR/prompts"
else
    SHELL_SPECIFIC_DIR=""
    SHELL_ENV_DIR=""
    SHELL_UTIL_DIR=""
    SHELL_ALIASES_DIR=""
    SHELL_COMPLETIONS_DIR=""
    SHELL_PROMPTS_DIR=""
fi

# Record shell-specific directories for startup debugging
dotfiles_record_startup_dir "$SHELL_ENV_DIR"
dotfiles_record_startup_dir "$SHELL_UTIL_DIR"
dotfiles_record_startup_dir "$SHELL_ALIASES_DIR"
dotfiles_record_startup_dir "$SHELL_COMPLETIONS_DIR"
dotfiles_record_startup_dir "$SHELL_PROMPTS_DIR"
