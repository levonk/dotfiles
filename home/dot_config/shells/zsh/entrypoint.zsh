#!/usr/bin/env zsh
# =====================================================================
# Zsh Entrypoint RC (sources universal sharedrc, then Zsh-specific logic)
# Managed by chezmoi | https://github.com/levonk/dotfiles
#
# Purpose:
#   - Entrypoint for Zsh shell startup
#   - Sources the universal shell-neutral sharedrc for all shared logic
#   - Appends Zsh-specific configuration and enhancements
#
# Compliance: See LICENSE and admin/licenses.md
# =====================================================================

# Source all files in the env/ directory
for config_file in ${XDG_CONFIG_HOME:-$HOME/.config}/shells/zsh/env/*; do
    if [[ -r "$config_file" ]] && [[ -f "$config_file" ]]; then
        # shellcheck source=/dev/null
        source "$config_file"
    fi
done

# Source all files in the util/ directory
for util_file in ${XDG_CONFIG_HOME:-$HOME/.config}/shells/zsh/util/*; do
    if [[ -r "$util_file" ]] && [[ -f "$util_file" ]]; then
        # shellcheck source=/dev/null
        source "$util_file"
    fi
done

# Source all files in the aliases/ directory
for alias_file in ${XDG_CONFIG_HOME:-$HOME/.config}/shells/zsh/aliases/*; do
    if [[ -r "$alias_file" ]] && [[ -f "$alias_file" ]]; then
        # shellcheck source=/dev/null
        source "$alias_file"
    fi
done

# Source all files in the completions/ directory
for comp_file in ${XDG_CONFIG_HOME:-$HOME/.config}/shells/zsh/completions/*; do
    if [[ -r "$comp_file" ]] && [[ -f "$comp_file" ]]; then
        # shellcheck source=/dev/null
        source "$comp_file"
    fi
done

# Source universal sharedrc (shell-neutral)
if [[ -r "${XDG_CONFIG_HOME:-$HOME/.config}/shells/shared/sharedrc" ]]; then
  # shellcheck source=/dev/null
  source "${XDG_CONFIG_HOME:-$HOME/.config}/shells/shared/sharedrc"
fi

# Export for compliance and test detection
export DOTFILES_ZSH_SHARED_LOADED=1
