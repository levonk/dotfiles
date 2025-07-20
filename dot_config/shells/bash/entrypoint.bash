# =====================================================================
# Bash Entrypoint RC (sources universal sharedrc, then Bash-specific logic)
# Managed by chezmoi | https://github.com/levonk/dotfiles
#
# Purpose:
#   - Entrypoint for Bash shell startup
#   - Sources the universal shell-neutral sharedrc for all shared logic
#   - Appends Bash-specific configuration and enhancements
#
# Compliance: See LICENSE and admin/licenses.md
# =====================================================================

# Source universal sharedrc (shell-neutral)
if [ -r "$HOME/.config/shells/shared/sharedrc" ]; then
  source "$HOME/.config/shells/shared/sharedrc"
fi

# --- Bash-specific logic below ---
# Load Bash-it if installed
if [ -d "$HOME/.bash_it" ]; then
  # shellcheck source=/dev/null
  source "$HOME/.bash_it/bash_it.sh"
fi

# Load Starship prompt if installed
if command -v starship >/dev/null 2>&1; then
  eval "$(starship init bash)"
fi

# Export for compliance and test detection
export DOTFILES_BASH_SHARED_LOADED=1
