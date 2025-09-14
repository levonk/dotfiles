#!/usr/bin/env zsh
# shellcheck shell=zsh
#{{- includeTemplate "dot_config/ai/templates/shell/sourceable.zsh.tmpl" (dict "path" .path "name" .name) -}}


# =====================================================================
#!/bin/bash
if [[ "" == "bash" ]]; then
  echo "ERROR: This script must be sourced, not executed."
  exit 1
fi
## Do not add a shebang so settings apply to your environment, not just this script

## Zsh-specific completion configuration
## - Sources shared history settings, then applies zsh options

## Only apply for interactive zsh
if [ -z "${ZSH_VERSION:-}" ]; then
  return 0 2>/dev/null || exit 0
fi
case $- in
  *i*) :;;
  *) return 0 2>/dev/null || exit 0;;
esac

autoload -Uz compinit

# Completion behavior: preserve trailing slash on directories
if [[ -n $ZSH_VERSION ]]; then
	zmodload zsh/complist 2>/dev/null || true

	# Use XDG cache for compdump and handle insecure dirs gracefully
	: ${XDG_CACHE_HOME:="$HOME/.cache"}
	_compdump="${XDG_CACHE_HOME}/zsh/.zcompdump"
	mkdir -p -- "${_compdump:h}"

	# Helper: run a command with optional timeout, capture stdout; never hard-fail
	local _have_timeout=0
	if (( $+commands[timeout] )) && [[ ${SHELL_INIT_TIMEOUT_SECS:-0} -gt 0 ]]; then
	  _have_timeout=1
	fi

	# Run compaudit safely with timebox
	local _audit_out="" _audit_rc=0
	if (( _have_timeout )); then
	  _audit_out=$(timeout ${SHELL_INIT_TIMEOUT_SECS}s compaudit 2>/dev/null || _audit_rc=$?)
	  if [[ ${_audit_rc} -ne 0 && ${_audit_rc} -ne 124 && ${_audit_rc} -ne 137 ]]; then
	    : # non-zero but not a timeout; ignore
	  fi
	  if [[ ${_audit_rc} -eq 124 || ${_audit_rc} -eq 137 ]]; then
	    print -P "%F{yellow}[zsh] compaudit timed out after ${SHELL_INIT_TIMEOUT_SECS}s; proceeding conservatively with compinit -i%f" >&2
	  fi
	else
	  _audit_out=$(compaudit 2>/dev/null || true)
	fi

	# Run compinit with optional timeout; use -i if audit found issues or timed out
	local _compinit_flags=()
	if [[ -n "${_audit_out}" ]] || [[ ${_audit_rc:-0} -eq 124 || ${_audit_rc:-0} -eq 137 ]]; then
	  [[ -z ${ZSH_COMPINIT_WARNED-} ]] && {
	    typeset -g ZSH_COMPINIT_WARNED=1
	    print -P "%F{yellow}[zsh] compaudit found insecure dirs or timed out; using compinit -i (please fix perms)%f" >&2
	  }
	  _compinit_flags=(-i)
	fi

	local _ci_rc=0
	if (( _have_timeout )); then
	  timeout ${SHELL_INIT_TIMEOUT_SECS}s compinit ${_compinit_flags[@]} -d "${_compdump}" 2>/dev/null || _ci_rc=$?
	  if [[ ${_ci_rc} -eq 124 || ${_ci_rc} -eq 137 ]]; then
	    print -P "%F{yellow}[zsh] compinit timed out after ${SHELL_INIT_TIMEOUT_SECS}s; skipping completion initialization for this session%f" >&2
	  fi
	else
	  compinit ${_compinit_flags[@]} -d "${_compdump}" 2>/dev/null || true
	fi

	# Compile dump to speed up subsequent loads
	if [[ -s "${_compdump}" && ( ! -s "${_compdump}.zwc" || "${_compdump}" -nt "${_compdump}.zwc" ) ]]; then
	  zcompile -R -- "${_compdump}" 2>/dev/null || true
	fi

	# Keep directory-friendly behavior and slash preservation
	setopt NO_AUTO_REMOVE_SLASH
	setopt AUTO_CD
	setopt AUTO_LIST AUTO_MENU LIST_TYPES MARK_DIRS AUTO_PARAM_SLASH
	unsetopt MENU_COMPLETE

	# Modern ergonomic completion styles
	zstyle ':completion:*' matcher-list \
	  'm:{a-z}={A-Z}' \
	  'r:|[._-]=* r:|=*' \
	  'l:|=*'
	zstyle ':completion:*' group-name ''
	zstyle ':completion:*' verbose yes
	zstyle ':completion:*:descriptions' format '%F{blue}-- %d --%f'
	zstyle ':completion:*:messages'     format '%F{yellow}%d%f'
	zstyle ':completion:*:warnings'     format '%F{red}! %d%f'
	zstyle ':completion:*' menu select=2
	zstyle ':completion:*' special-dirs true
	zstyle ':completion:*' squeeze-slashes true

	# Colorized completion lists leveraging LS_COLORS
	if (( $+commands[dircolors] )); then
	  eval "$(dircolors -b 2>/dev/null || true)"
	fi
	zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}

	# Insert unambiguous portion immediately; accept exact dirs as typed
	zstyle ':completion:*' insert-unambiguous true
	zstyle ':completion:*' accept-exact-dirs true
fi
