#!/usr/bin/env sh
# shellcheck shell=sh
#{{- includeTemplate "dot_config/ai/snippets/shell/sourceable.sh.tmpl" (dict "path" .path "name" .name) -}}

# =====================================================================

#------------------------------------------------------------------------------
# Editor Configuration
# Only set if not already defined
#------------------------------------------------------------------------------
: "${EDITOR:=nvim}"         # Default editor for CLI tools
: "${VISUAL:=nvim}"         # Used by some GUI wrappers or fallback editors
: "${CVSEDITOR:=nvim}"      # Used by CVS version control
: "${GIT_EDITOR:=nvim}"     # Git commit/edit operations
: "${WORDCHARS:='*?_-.[]~=&;!#$%^(){}<>;'}"  # Word characters for line editor

export EDITOR VISUAL CVSEDITOR GIT_EDITOR WORDCHARS
