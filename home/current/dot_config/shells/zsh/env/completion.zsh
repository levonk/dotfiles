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

	if compaudit 2>/dev/null | read -r insecure; then
	  [[ -z ${ZSH_COMPINIT_WARNED-} ]] && {
	    typeset -g ZSH_COMPINIT_WARNED=1
	    print -P "%F{yellow}[zsh] compaudit found insecure dirs; using compinit -i (please fix perms)%f"
	  }
	  compinit -i -d "${_compdump}"
	else
	  compinit -d "${_compdump}"
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
