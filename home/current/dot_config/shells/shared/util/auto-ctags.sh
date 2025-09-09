# shellcheck shell=sh
#!/bin/bash
if [[ "" == "bash" ]]; then
  echo "ERROR: This script must be sourced, not executed."
  exit 1
fi
#!/bin/bash

## ctags indexes all the identifiers in source code for rapid navigation
## The following files make it so entry into a directory automatically
## initializes index

## ~/.zshrc or ~/.bashrc
function auto_ctags() {
  # Skip running in the home directory to avoid indexing $HOME
  if [ "$PWD" = "$HOME" ] || [ "$PWD/" = "$HOME/" ]; then
    return 0
  fi
  if [ -f ".ctags" ] || [ -d "src" ]; then
    echo "Indexing with ctags..."
    ctags -R .
  fi
}

## Under Zsh defined in `$XDG_CONFIG_HOME/shells/zsh/util/auto-ctags.zsh`
# `autoload -U add-zsh-hook`
# `add-zsh-hook chpwd auto_ctags`

## Under Bash defined in `$XDG_CONFIG_HOME/shells/bash/util/auto-ctags.bash`
# `export PROMPT_COMMAND="auto_ctags; $PROMPT_COMMAND"`
