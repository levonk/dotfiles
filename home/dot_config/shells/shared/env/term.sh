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
    export TERM="xterm-256color"  # More common, consider a fallback
fi
alias reset='TERM=xterm-256color reset'  # Consistent

# Enables colored output in commands like ls (if the command supports it). This setting is generally safe to set unconditionally.
export CLICOLOR=1

# Explicitly set TERM based on OS/environment (after the more general xterm-256color)
# linux terminal type is often a better match for the Linux console itself (if you're not using a terminal emulator).
if [[ "$OSTYPE" == linux* ]]; then
    # Check if TERM is still the default xterm-256color
    if [[ "$TERM" == "xterm-256color" ]]; then
		#  If you're using a terminal emulator within Linux (e.g., GNOME Terminal, Konsole, xterm), you almost certainly don't want to force TERM to linux.
        export TERM=linux
    fi
fi