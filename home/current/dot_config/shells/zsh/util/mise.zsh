export MISE_SHELL=zsh
# Source shared mise utilities (PATH setup and `mise()` wrapper)
_mise_shared="${XDG_CONFIG_HOME:-$HOME/.config}/shells/shared/util/mise.sh"
[ -r "$_mise_shared" ] && . "$_mise_shared"
if [ -z "${_MISE_BIN:-}" ]; then
  _MISE_BIN="$HOME/.local/bin/mise"
fi

_mise_hook() {
  eval "$("$_MISE_BIN" hook-env -s zsh)";
}
typeset -ag precmd_functions;
if [[ -z "${precmd_functions[(r)_mise_hook]+1}" ]]; then
  precmd_functions=( _mise_hook ${precmd_functions[@]} )
fi
typeset -ag chpwd_functions;
if [[ -z "${chpwd_functions[(r)_mise_hook]+1}" ]]; then
  chpwd_functions=( _mise_hook ${chpwd_functions[@]} )
fi

_mise_hook
if [ -z "${_mise_cmd_not_found:-}" ]; then
    _mise_cmd_not_found=1
    [ -n "$(declare -f command_not_found_handler)" ] && eval "${$(declare -f command_not_found_handler)/command_not_found_handler/_command_not_found_handler}"

    function command_not_found_handler() {
        if [[ "$1" != "mise" && "$1" != "mise-"* ]] && "$_MISE_BIN" hook-not-found -s zsh -- "$1"; then
          _mise_hook
          "$@"
        elif [ -n "$(declare -f _command_not_found_handler)" ]; then
            _command_not_found_handler "$@"
        else
            echo "zsh: command not found: $1" >&2
            return 127
        fi
    }
fi
eval "$("$_MISE_BIN" activate zsh)"
