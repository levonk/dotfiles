#!/usr/bin/env zsh
# shellcheck shell=zsh
#{{- includeTemplate "dot_config/ai/templates/shell/sourceable.zsh.tmpl" (dict "path" .path "name" .name) -}}


# =====================================================================
# Zsh Global Directory Navigation Aliases
# Purpose:
#   - Provide zsh-only global aliases for fast upward directory traversal.
#   - Complements shared `dirnav.sh` functions without impacting other shells.
# =====================================================================

# Global directory shorthand (usable anywhere in a command line)
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
