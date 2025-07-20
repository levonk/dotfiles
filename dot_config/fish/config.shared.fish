# =====================================================================
# Fish Shared Config (sources universal sharedrc, then Fish-specific logic)
# Managed by chezmoi | https://github.com/levonk/dotfiles
#
# Purpose:
#   - Sources the universal shell-neutral sharedrc for all shared logic
#   - Appends Fish-specific configuration and enhancements
#
# Compliance: See LICENSE and admin/licenses.md
# =====================================================================

# Source universal sharedrc (shell-neutral) using bash wrapper
if test -r "$HOME/.config/shells/shared/sharedrc"
    bash -c "source '$HOME/.config/shells/shared/sharedrc'"
end

# --- Fish-specific logic below ---
# Load Oh My Fish if installed
if test -d "$HOME/.local/share/omf"; and test -f "$HOME/.local/share/omf/init.fish"
    source "$HOME/.local/share/omf/init.fish"
end

# Load Starship prompt if installed
if type -q starship
    starship init fish | source
end

# Export for compliance and test detection
set -gx DOTFILES_FISH_SHARED_LOADED 1
