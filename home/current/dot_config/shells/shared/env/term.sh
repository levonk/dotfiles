#!/usr/bin/env sh
# shellcheck shell=sh
#{{- includeTemplate "dot_config/ai/templates/shell/sourceable.sh.tmpl" (dict "path" .path "name" .name) -}}


# =====================================================================

#------------------------------------------------------------------------------
# Terminal Information
#------------------------------------------------------------------------------

# Determine the operating system
UNAME=$(uname)

# Check for custom terminfo directory
if [[ -d "$HOME/lib/$UNAME/terminfo" ]]; then
	# tells ncurses (the library used by many terminal applications) where to find terminal descriptions.
    export TERMINFO="$HOME/lib/$UNAME/terminfo"
fi

# Set TERM and create reset alias
if [[ -z "$TERM" ]]; then  # Only set TERM if it's not already set
    export TERM="xterm-256color"  # sensible default for emulators supporting 256 colors
fi
alias reset='TERM=xterm-256color reset'  # Consistent

# Enables colored output in commands like ls (if the command supports it). This setting is generally safe to set unconditionally.
export CLICOLOR=1

# Do NOT force TERM=linux. Many terminfo capabilities (e.g., smkx) are missing in 'linux'.
# Rely on the terminal emulator to set TERM appropriately; we only provide a default when TERM is empty.
