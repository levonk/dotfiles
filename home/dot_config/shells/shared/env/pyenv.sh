export PYENV_ROOT="$HOME/.config/pyenv"
PYENV_BIN="$PYENV_ROOT/bin"

if [ -x "$PYENV_BIN/pyenv" ]; then
  case ":$PATH:" in
    *":$PYENV_BIN:"*) ;;
    *) export PATH="$PYENV_BIN:$PATH" ;;
  esac
fi

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

