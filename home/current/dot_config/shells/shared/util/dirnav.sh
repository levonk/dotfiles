#!/usr/bin/env sh
# shellcheck shell=sh
#{{- includeTemplate "dot_config/ai/snippets/shell/sourceable.sh.tmpl" (dict "path" .path "name" .name) -}}


# =====================================================================

# This file is managed by chezmoi (https://www.chezmoi.io/) and maintained at https://github.com/levonk/dotfiles
# Directory navigation aliases and functions (from legacy sharedrc and aliases)
# Includes:
#   - Up-directory aliases (..2, ..3, ...)
#   - cdb: cd up N directories
#   - mkcd: mkdir -p <dir> && cd <dir> (shell-neutral, XDG-compliant)

# Create and enter a directory (mkdir -p {input} && cd {input})
mkcd() {
  if [ -z "$1" ]; then
    echo "Usage: mkcd <directory>" >&2
    return 1
  fi
  mkdir -p -- "$1" && cd -- "$1"
}
# Alias for quick access
alias mcd='mkcd'

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

# Aliases for navigating up directories
alias ..2='cd ../..'
alias ..3='cd ../../..'
alias ..4='cd ../../../..'
alias ..5='cd ../../../../../..'
alias ..6='cd ../../../../../../..'
alias ..7='cd ../../../../../../../..'
alias ..8='cd ../../../../../../../../..'
alias ..9='cd ../../../../../../../../../..'

# Function to cd out n directories
cdb() {
    range=$(eval "echo '{1..$1}'");
    toPrint="'../%.0s' $range";
    printfToEval=$(echo "printf $toPrint");
    toCd=$(eval $printfToEval);
    eval "cd $toCd";
    pwd;
}

# open current directory in Mac Finder
alias o="open ."
