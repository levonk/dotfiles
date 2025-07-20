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

# Source universal sharedrc (shell-neutral)
if [ -r "$HOME/.config/shells/shared/sharedrc" ]; then
  source "$HOME/.config/shells/shared/sharedrc"
fi

# --- Zsh-specific logic below ---
s.sh" ]; then
  . "$HOME/.config/shells/shared/alias-helpers.sh"
fi
# Modern tool notification and spell correction (real-time)
if [ -r "$HOME/.config/shells/shared/modern-tool-notify.sh" ]; then
  . "$HOME/.config/shells/shared/modern-tool-notify.sh"
fi

#------------------------------------------------------------------------------
# EC2 Instance Configuration
#------------------------------------------------------------------------------
in_ec2=0  # Initialize to a default value
if [[ -f /etc/tweetup/tweetup.properties ]]; then
    if grep -q -w '^ec2' /etc/tweetup/tweetup.properties; then
        in_ec2=1 # Much simpler check
    fi
fi

if (( in_ec2 )); then
    ec2_secgroups=($(curl -s "http://169.254.169.254/latest/meta-data/security-groups"))
    if [[ -n "${ec2_secgroups[0]}" ]]; then # Ensure we have data
        ec2_sg="${ec2_secgroups[0]#*-*-}"
        ec2_univ="${ec2_secgroups[0]%%-*-}" # Simplified
    fi
fi

#------------------------------------------------------------------------------
# cdargs Integration
#------------------------------------------------------------------------------
CDARGS=/usr/share/doc/cdargs/examples/cdargs-bash.sh
if [[ -f "$CDARGS" ]]; then  # Quote the variable!
    source "$CDARGS"
fi

#------------------------------------------------------------------------------
# Less Configuration
#------------------------------------------------------------------------------
export LESS="--RAW-CONTROL-CHARS --ignore-case --quit-at-eof --quit-if-one-screen --follow-name --HILITE-SEARCH --LONG-PROMPT --squeeze-blank-lines --tabs=4"

#------------------------------------------------------------------------------
# Terminal Handling
#------------------------------------------------------------------------------
if [[ "$TERM" == "dumb" ]]; then
    unset zle  # Correct way to disable zsh's line editor
    unset prompt_cr
    unset prompt_subst
    unset precmd
    unset preexec
    PS1='$ '
else
    # Source zsh prompt file if available
    if [[ -r ~/.zshprompt ]]; then
        source ~/.zshprompt
    elif [[ -r ~/Dotfiles/zshprompt ]]; then
        source ~/Dotfiles/zshprompt
    else
        export RPROMPT='      20%D %*'
        {
            if (( UID == 0 )); then
                local BOLD="%b" ; local bold="%B"
                local UNDR="%u" ; local undr="%U"
            else
                local BOLD="%B" ; local bold="%b"
                local UNDR="%U" ; local undr="%u"
            fi

            # prefix with the name of the screen session
            local prefix=""
            if [[ -n "$STY" ]]; then
                prefix="${BOLD}${STY:t}${bold}:" # Just use filename portion
            fi
            local suffix=""

            export PROMPT="${undr}%n@${prefix}%m${suffix}:${UNDR}%y${undr}:%4c%u%#"
            unset BOLD ; unset bold ; unset UNDR ; unset undr
        }
    fi
fi

#------------------------------------------------------------------------------
# Editor Configuration
#------------------------------------------------------------------------------
export EDITOR=vim
export CVSEDITOR=vim

#------------------------------------------------------------------------------
# Word Characters for Line Editor
#------------------------------------------------------------------------------
export WORDCHARS='*?_-.[]~=&;!#$%^(){}<>;'

#------------------------------------------------------------------------------
# Terminal Information
#------------------------------------------------------------------------------
if [[ -d "$HOME/lib/${UNAME}/terminfo" ]]; then
    export TERMINFO="$HOME/lib/${UNAME}/terminfo"
    export TERM=xterm-256color #More common, consider a fallback
    alias reset='TERM=xterm-256color reset' #Consistent
fi
export CLICOLOR=1

# Explicitly set TERM based on OS/environment
if [[ "$OSTYPE" == linux* ]]; then
    export TERM=linux
fi

#------------------------------------------------------------------------------
# History Configuration
#------------------------------------------------------------------------------
HISTCONTROL=ignoreboth:erasedups # include erasedups!
HISTSIZE=50000
HISTTIMEFORMAT='<%F %T>' # Simplified
HISTFILE="$HOME/.bogushist"  # Quote the variable
export HISTCONTROL HISTSIZE HISTFILE HISTTIMEFORMAT

#------------------------------------------------------------------------------
# Command Timing
#------------------------------------------------------------------------------
export REPORTTIME=1

#------------------------------------------------------------------------------
# Zsh Function Path Configuration
#------------------------------------------------------------------------------
fpath=(${HOME}/Dotfiles/zsh-functions $fpath)
typeset -U fpath

#------------------------------------------------------------------------------
# Package Config Path
#------------------------------------------------------------------------------
if [[ -n "$ROOT" ]]; then
    export PKG_CONFIG_PATH="${ROOT}/lib/pkgconfig"
    typeset -U PKG_CONFIG_PATH
fi

#------------------------------------------------------------------------------
# Autoload Zsh Functions
#------------------------------------------------------------------------------
for f in "${HOME}/Dotfiles/zsh-functions/"*; do
    if [[ -f "$f" && ! "$f" == *~ ]]; then
        autoload -Uz "$f:t" # Force recompile with -U
    fi
done

#------------------------------------------------------------------------------
# File Globbing and Completion Ignored Files
#------------------------------------------------------------------------------
fignore=(CVS $fignore) # Simpler assignment
typeset -U fignore

#------------------------------------------------------------------------------
# Zsh Completion Initialization
#------------------------------------------------------------------------------
autoload -Uz compinit # Add -U and force recompile
compinit

#------------------------------------------------------------------------------
# Zsh-move setup
#------------------------------------------------------------------------------
autoload -Uz zmv

#------------------------------------------------------------------------------
# Completions setup, deprecated I don't know where this is
#------------------------------------------------------------------------------
#if [[ -f setup-completions ]]; then
#    setup-completions
#fi

#------------------------------------------------------------------------------
# Zsh Completion Options
#------------------------------------------------------------------------------
setopt autolist
unsetopt menucomplete

#------------------------------------------------------------------------------
# Zsh Key Bindings
#------------------------------------------------------------------------------
# bindkey -e # Emacs mode (default)
bindkey -v  # Vi mode
bindkey '\e[3~' delete-char
bindkey '^R' history-incremental-search-backward

#------------------------------------------------------------------------------
# SSH Agent Configuration
#------------------------------------------------------------------------------
PRIVATE_KEY_FILE_DSA="$HOME/.ssh/id_dsa"
PRIVATE_KEY_FILE_RSA="$HOME/.ssh/id_rsa"
PRIVATE_KEY_FILE="$PRIVATE_KEY_FILE_RSA" # Default to RSA

if [[ ! -S "$SSH_AUTH_SOCK" ]]; then  # Check if agent is running
    if [[ -f "$PRIVATE_KEY_FILE" ]]; then
        AGENT_FILE="$HOME/.ssh/ssh-agent.dat"

        if [[ -f "$AGENT_FILE" ]]; then
            if eval "$(cat "$AGENT_FILE")" &> /dev/null; then
                # Agent environment loaded successfully
                ssh-add -l &> /dev/null || ssh-add "$PRIVATE_KEY_FILE" # Only add if not already present
            else
                echo "Warning: Failed to load SSH agent environment from $AGENT_FILE. Starting new agent."
                rm -f "$AGENT_FILE" # Remove corrupt file
                ssh-agent -s > "$AGENT_FILE"
                eval "$(cat "$AGENT_FILE")"
                ssh-add "$PRIVATE_KEY_FILE"
            fi
        else
            # Agent environment file doesn't exist, start new agent
            ssh-agent -s > "$AGENT_FILE"
            eval "$(cat "$AGENT_FILE")"
            ssh-add "$PRIVATE_KEY_FILE"
        fi
    fi
fi

#------------------------------------------------------------------------------
# Body Function
#------------------------------------------------------------------------------
body() {
    IFS= read -r header
    printf '%s\n' "$header"
    "$@"
}

#------------------------------------------------------------------------------
# Global Aliases
#------------------------------------------------------------------------------
alias -g ...=../..
alias -g /...=/../..
alias -g ....=../../..
alias -g .....=../../../..
alias -g ......=../../../../..
alias -g .......=../../../../../..
alias -g ........=../../../../../../..
alias -g /..2=/../..
alias -g /..3=/../../..
alias -g /..4=/../../../..
alias -g /..5=/../../../../..
alias -g /..6=/../../../../../..
alias -g /..7=/../../../../../../..
alias -g /..8=/../../../../../../../..
alias -g /..9=/../../../../../../../../..
alias -g ..2=../../
alias -g ..3=../../../
alias -g ..4=../../../../
alias -g ..5=../../../../../
alias -g ..6=../../../../../../
alias -g ..7=../../../../../../../
alias -g ..8=../../../../../../../../
alias -g ..9=../../../../../../../../../

#------------------------------------------------------------------------------
# cd Aliases
#------------------------------------------------------------------------------
alias ..2='cd ../../'
alias ..3='cd ../../../'
alias ..4='cd ../../../../'
alias ..5='cd ../../../../../'
alias ..6='cd ../../../../../../'
alias ..7='cd ../../../../../../../'
alias ..8='cd ../../../../../../../../'
alias ..9='cd ../../../../../../../../../'

#------------------------------------------------------------------------------
# cdb function: cd up multiple directories
#------------------------------------------------------------------------------
cdb() {
  if [[ ! "$1" =~ ^[0-9]+$ ]]; then
    echo "Usage: cdb <number_of_directories>" >&2
    return 1
  fi

  local target=$(printf "../%.0s" $(seq 1 "$1"))
  cd "$target"
  pwd
}

#------------------------------------------------------------------------------
# new-alias function: Create a new alias from the last command
#------------------------------------------------------------------------------
new-alias() {
  if [[ -z "$1" ]]; then
    echo "Usage: new-alias <alias_name>" >&2
    return 1
  fi
  local last_command=$(history 1 | sed 's/^[ ]*[0-9]*[ ]*//')
  echo "alias $1='$last_command'" >> "$HOME/.sharedrc"
  source "$HOME/.sharedrc"
}

#------------------------------------------------------------------------------
# History Search Keybindings
#------------------------------------------------------------------------------
bindkey '^p' history-beginning-search-backward  # Ctrl+p
bindkey '^n' history-beginning-search-forward   # Ctrl+n

#------------------------------------------------------------------------------
# xml formatter
#------------------------------------------------------------------------------
xmlfmt() {
  xmllint --format --recover "$1" > "$1"
}

#------------------------------------------------------------------------------
# Apache Maven via docker
#------------------------------------------------------------------------------
mvnd() {
  docker run --rm -it -v "$HOME/.m2:/home/user/.m2" -v "$(pwd):/workdir" levonk/maven:latest "$@"
}

#------------------------------------------------------------------------------
# Stupid login stuff
#------------------------------------------------------------------------------
if command -v fortune &> /dev/null; then
  fortune -ac
fi

if command -v xmlstarlet &> /dev/null; then
  xmlstarlet sel --net -t -m '/rss/channel/item/description' -v '.' 'http://dictionary.reference.com/wordoftheday/wotd.rss'
fi