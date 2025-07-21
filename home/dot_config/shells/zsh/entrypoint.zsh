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

# cmd check
setopt casematch # make regex case sensitive
setopt nocaseglob # Make completion case-sensitive
# to revert
#unsetopt nocaseglob # Make completion case-insensitive (default)

setopt correct # Enable command correction


#------------------------------------------------------------------------------
# Shell History
#------------------------------------------------------------------------------
export HISTFILESIZE=1000
## SAVEHIST: This variable controls the number of commands that are saved to the HISTFILE when you close the shell session. It determines how many lines from the in-memory history are written to the $HISTFILE for use in future sessions.
##     When you start a new Zsh session, it reads the HISTFILE, loads the last SAVEHIST commands into memory (up to the HISTSIZE limit), and then starts adding new commands to the in-memory history.
SAVEHIST=5000
mkdir -p ~/.cache/zsh
HISTFILE=~/.cache/zsh/.zsh_history
# Execution timestamp shown in the history command output.
# The optional three formats: "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
HIST_STAMPS="yyyy-mm-dd"

## zsh options doc
## https://zsh.sourceforge.io/Doc/Release/Options.html

#  When enabled, histappend appends new commands to the history file instead of overwriting it when the shell exits. This ensures that you keep a complete history of commands across multiple sessions.
setopt hist_append # appends new command to the history file
setopt inc_append_history # appends each cmd to history file immediately after execution, rather than wait for shell exit.
setopt share_history # Share command history between all zsh instances.
setopt hist_expire_dups_first
setopt hist_fcntl_lock # use higher performance history file locking if available
setopt hist_ignore_dups # if it's an immediate repeat, don't store
setopt hist_ignore_space # leading space means don't add to history
setopt hist_no_store # don't add the history cmd itself to history
setopt hist_reduce_blanks # remove excess blanks
setopt hist_save_no_dups # when saving history, don't save dupes

# Changing directory options
setopt autocd # you don't need the cd command to go to subdir
setopt cdablevars # look in home dir if its not in current or root
# Completion directory options
setopt autolist # Automatically list choices on ambiguous completions
setopt automenu # launch menu after repeated failed completions
unsetopt listbeep # don't beep at me for failed completions
setopt listtypes # add a symbol representing the type of file during completions
setopt markdirs # appen trailing / to all directory names after globbing

# Prompt changes
setopt multibyte # support multi-byte characters
setopt warncreateglobal # Warn if setting a global var
setopt warnnestedvar # warn if setting a nested variable
setopt print_exit_value # print the exit value if it's non-zero
setopt rm_star_wait # wait 10 sec before allowing user to answer no to a rm * or rm path/*
setopt prompt_bang # '!' is treated specially in prompt expansion
setopt prompt_sp # show a character denoting multiline prompt commands
unsetopt beep # dont beep at me
setopt vi # vi editing mode
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


# Process settings
setopt auto_continue # disown running job lets it continue
setopt bg_nice # automatically nice background processes


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
    if [[ -r ~/.config/shell/zsh/.zshprompt ]]; then
        source ~/.config/shell/zsh/.zshprompt
    elif [[ "replaced-by" == "powerlevel10k" ]]; then
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
# Command Timing
#------------------------------------------------------------------------------
export REPORTTIME=1

#------------------------------------------------------------------------------
# Zsh Function Path Configuration
#------------------------------------------------------------------------------
fpath=(${HOME}/.config/shells/zsh/zsh-functions $fpath)
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
for f in "${HOME}/.config/shells/zsh/zsh-functions/"*; do
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
# SSH Agent Configuration
#------------------------------------------------------------------------------
PRIVATE_KEY_FILE_DSA="$HOME/.ssh/id_dsa"
PRIVATE_KEY_FILE_RSA="$HOME/.ssh/id_rsa"
PRIVATE_KEY_FILE="$PRIVATE_KEY_FILE_RSA" # Default to RSA

#if [[ ! -S "$SSH_AUTH_SOCK" ]]; then  # Check if agent is running
#    if [[ -f "$PRIVATE_KEY_FILE" ]]; then
#        AGENT_FILE="$HOME/.ssh/ssh-agent.dat"
#
#        if [[ -f "$AGENT_FILE" ]]; then
#            if eval "$(cat "$AGENT_FILE")" &> /dev/null; then
#                # Agent environment loaded successfully
#                ssh-add -l &> /dev/null || ssh-add "$PRIVATE_KEY_FILE" # Only add if not already present
#            else
#                echo "Warning: Failed to load SSH agent environment from $AGENT_FILE. Starting new agent."
#                rm -f "$AGENT_FILE" # Remove corrupt file
#                ssh-agent -s > "$AGENT_FILE"
#                eval "$(cat "$AGENT_FILE")"
#                ssh-add "$PRIVATE_KEY_FILE"
#            fi
#        else
#            # Agent environment file doesn't exist, start new agent
#            ssh-agent -s > "$AGENT_FILE"
#            eval "$(cat "$AGENT_FILE")"
#            ssh-add "$PRIVATE_KEY_FILE"
#        fi
#    fi
#fi

#------------------------------------------------------------------------------
# Body Function
#------------------------------------------------------------------------------
body() {
    IFS= read -r header
    printf '%s\n' "$header"
    "$@"
}

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