export PYENV_ROOT="$HOME/.config/pyenv"
[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"

# Conditionally set shell completions if it's not already set correctly
if [[ -z "$PYENV" || ! -e "$PYENV" ]]; then
  if [[ -n "$ZSH_VERSION" ]]; then
    # We're in Zsh
	eval "$(pyenv init - zsh)"
  elif [[ -n "$BASH_VERSION" ]]; then
    # We're in Bash
	eval "$(pyenv init - bash)"
  fi
fi

