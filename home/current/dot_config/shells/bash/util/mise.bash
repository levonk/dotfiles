# shellcheck shell=sh
#!/bin/bash
if [[ "" == "bash" ]]; then
  echo "ERROR: This script must be sourced, not executed."
  exit 1
fi
# Bash-specific mise integration
# Sources shared shell-neutral logic and adds bash hooks

export MISE_SHELL=bash

# Source shared mise utilities (PATH setup and `mise()` wrapper)
_mise_shared="${XDG_CONFIG_HOME:-$HOME/.config}/shells/shared/util/mise.sh"
[ -r "$_mise_shared" ] && . "$_mise_shared"
if [ -z "${_MISE_BIN:-}" ]; then
  _MISE_BIN="$HOME/.local/bin/mise"
fi

# Hook function to refresh env from mise
_mise_hook() {
  eval "$("$_MISE_BIN" hook-env -s bash)"
}

# Add _mise_hook to PROMPT_COMMAND if not already present
case ";${PROMPT_COMMAND:-};" in
  *"_mise_hook"*) : ;;
  *)
    if [ -n "${PROMPT_COMMAND:-}" ]; then
      PROMPT_COMMAND="_mise_hook; ${PROMPT_COMMAND}"
    else
      PROMPT_COMMAND="_mise_hook"
    fi
    ;;
esac

# Also run _mise_hook on directory change by wrapping cd (like util-nvm)
cdmise() {
  builtin cd "$@" || return $?
  _mise_hook
}
# Only alias cd if not already aliased by another tool that we can't co-exist with
# If an alias already exists, we won't override it; PROMPT_COMMAND still keeps env fresh
if ! alias cd >/dev/null 2>&1; then
  alias cd='cdmise'
fi

# command-not-found integration
if [ -z "${_mise_cmd_not_found:-}" ]; then
  _mise_cmd_not_found=1
  # Preserve any existing handler by renaming it
  if [ -n "$(declare -f command_not_found_handle)" ]; then
    eval "$(declare -f command_not_found_handle | sed '1s/command_not_found_handle/_command_not_found_handle/')"
  fi

  command_not_found_handle() {
    if [ "$1" != "mise" ] && [ "${1#mise-}" != "$1" ] ; then
      : # don't recurse on mise subcommands
    elif "$_MISE_BIN" hook-not-found -s bash -- "$1"; then
      _mise_hook
      "$@"
      return $?
    fi

    if [ -n "$(declare -f _command_not_found_handle)" ]; then
      _command_not_found_handle "$@"
    else
      printf 'bash: %s: command not found\n' "$1" >&2
      return 127
    fi
  }
fi

# Activate mise for bash
eval "$("$_MISE_BIN" activate bash)"
