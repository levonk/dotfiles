# This file is managed by chezmoi (https://www.chezmoi.io/) and maintained at https://github.com/levonk/dotfiles
# Alias helpers and directory bookmarking logic (from sharedrc and aliases)

# Helper to create a new alias for the last command (XDG-compliant)
# Persistent aliases are stored in $XDG_CONFIG_HOME/shells/shared/sharedrc
new-alias() {
  : "${XDG_CONFIG_HOME:=$HOME/.config}"
  local SHAREDRC="$XDG_CONFIG_HOME/shells/shared/sharedrc"
  mkdir -p "$(dirname "$SHAREDRC")"
  local last_command=$(echo "$(history | tail -n2 | head -n1)" | sed 's/[0-9]* //')
  echo alias "$1"="'"$last_command"'" >> "$SHAREDRC"
  . "$SHAREDRC"
}

# Directory bookmarking system
alias m1='alias g1="cd $PWD"'
alias m2='alias g2="cd $PWD"'
alias m3='alias g3="cd $PWD"'
alias m4='alias g4="cd $PWD"'
alias m5='alias g5="cd $PWD"'
alias m6='alias g6="cd $PWD"'
alias m7='alias g7="cd $PWD"'
alias m8='alias g8="cd $PWD"'
alias m9='alias g9="cd $PWD"'
alias m0='alias g0="cd $PWD"'
: "${XDG_STATE_HOME:=$HOME/.local/state}"
BOOKMARKS_DIR="$XDG_STATE_HOME/shells/working"
mkdir -p "$BOOKMARKS_DIR"
BOOKMARKS_FILE="$BOOKMARKS_DIR/.cdbookmarks"

if [[ "$SHELL" == '/bin/bash' ]]; then
  alias msave="alias|grep -e 'alias g[0-9]'|grep -v 'alias m' > '$BOOKMARKS_FILE'"
  alias mprint="alias|grep -e 'alias g[0-9]'|grep -v 'alias m' | sed 's/alias //'"
else
  alias msave="alias|grep -e '^g[0-9]' > '$BOOKMARKS_FILE'"
  alias mprint="alias|grep -e '^g[0-9]'"
fi
touch "$BOOKMARKS_FILE"
source "$BOOKMARKS_FILE"
