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

export XDG_DATA_HOME=$HOME/.local/share
export XDG_CONFIG_HOME=$HOME/.config
export XDG_STATE_HOME=$HOME/.local/state
export XDG_CACHE_HOME=$HOME/.cache

# Source universal sharedrc (shell-neutral) using bash wrapper
if test -r "$HOME/.config/shells/shared/sharedrc"
    bash -c "source '$HOME/.config/shells/shared/sharedrc'"
end

# --- Fish-specific logic below ---

# Set the number of events in history, can't control lines
set -g fish_history_max_size 5000

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
