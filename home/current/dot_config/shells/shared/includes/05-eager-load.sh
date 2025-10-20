#!/usr/bin/env sh
# shellcheck shell=sh

# =============================================================================
# 05-eager-load.sh
#
# ## Purpose
#
# - Eagerly loads essential modules that are required for the shell to be
#   functional immediately upon startup.
# - Sources XDG environment, essential aliases, and shell-specific configs.
# =============================================================================

start_timing "essential_preload"

# Define shell extensions to be sourced
_shell_exts="sh bash env"
if [ "$CURRENT_SHELL" = "zsh" ]; then
    _shell_exts="zsh sh bash env"
fi

# Load essential environment variables first (XDG compliance)
XDG_DIRS_ENV="$ENV_DIR/__xdg-env.sh"
if [ -r "$XDG_DIRS_ENV" ]; then
    enhanced_safe_source "$XDG_DIRS_ENV" "XDG environment variables"
fi

# Preload essential modules (e.g., modern-tools aliases)
if command -v preload_essential_modules >/dev/null 2>&1; then
    preload_essential_modules
else
    # Fallback: load essential shared aliases directly
    if [ -r "$ALIASES_DIR/modern-tools.sh" ]; then
        enhanced_safe_source "$ALIASES_DIR/modern-tools.sh" "Modern tools aliases (shared)"
    fi
fi

# Eagerly load all shell-specific and shared modules
if [ -n "$SHELL_ENV_DIR" ] && [ -d "$SHELL_ENV_DIR" ]; then
    _source_modules_from_dir "$SHELL_ENV_DIR" "${CURRENT_SHELL} environment" "$_shell_exts" 0
fi
if [ -d "$ENV_DIR" ]; then
    _source_modules_from_dir "$ENV_DIR" "Shared environment" "sh bash env" 1 "^__xdg-env\\.sh$"
fi

_source_modules_from_dir "$UTIL_DIR" "Shared utils" "sh bash env" 1
_source_modules_from_dir "$ALIASES_DIR" "Shared aliases" "sh bash env" 1
_source_modules_from_dir "$SHELLS_SHARED_DIR/prompts" "Shared prompts" "sh bash env" 1

if [ -n "$CURRENT_SHELL" ] && [ "$CURRENT_SHELL" != "unknown" ]; then
    _source_modules_from_dir "$SHELL_ALIASES_DIR" "${CURRENT_SHELL} aliases" "$_shell_exts" 0
    _source_modules_from_dir "$SHELL_PROMPTS_DIR" "${CURRENT_SHELL} prompts" "$_shell_exts" 0
fi


unset _shell_exts

# Eagerly source Zsh plugin manager and prompt to ensure prompt is set early
if [ "$CURRENT_SHELL" = "zsh" ]; then
    if [ -r "$SHELL_UTIL_DIR/om-my-zsh-plugins.zsh" ]; then
        enhanced_safe_source "$SHELL_UTIL_DIR/om-my-zsh-plugins.zsh" "Zsh oh-my-zsh plugins"
    fi
    if [ -r "$SHELL_PROMPTS_DIR/p10k.zsh" ]; then
        enhanced_safe_source "$SHELL_PROMPTS_DIR/p10k.zsh" "Zsh prompt (p10k)"
        export DOTFILES_PROMPT_SOURCED=1
    elif [ -r "$SHELL_PROMPTS_DIR/prompt.zsh" ]; then
        enhanced_safe_source "$SHELL_PROMPTS_DIR/prompt.zsh" "Zsh prompt (legacy)"
        export DOTFILES_PROMPT_SOURCED=1
    fi
fi

end_timing "essential_preload" "Essential modules preload"
