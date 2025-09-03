# This file is managed by chezmoi (https://www.chezmoi.io/) and maintained at https://github.com/levonk/dotfiles

# =====================================================================
# Bash Key Bindings
# =====================================================================

# Bash doesn't directly support history substring search on arrow keys like zsh.
# We can approximate it using readline variables and bind.

# Set readline variables to use history substring search on up/down arrows
bind '"\e[A": history-search-backward'
bind '"\e[B": history-search-forward'

# Ctrl+a goes to the beginning of the line
bind '^a:beginning-of-line'
# Ctrl+e goes to the end of the line
bind '^e:end-of-line'

# =====================================================================
# End of Bash Key Bindings
# =====================================================================
