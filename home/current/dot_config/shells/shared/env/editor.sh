# shellcheck shell=sh
#!/bin/bash
if [[ "" == "bash" ]]; then
  echo "ERROR: This script must be sourced, not executed."
  exit 1
fi

#------------------------------------------------------------------------------
# Editor Configuration
#------------------------------------------------------------------------------
export EDITOR=nvim         # Default editor for CLI tools
export VISUAL=nvim         # Used by some GUI wrappers or fallback editors
export CVSEDITOR=nvim      # Used by CVS version control
export GIT_EDITOR=nvim     # Git commit/edit operations

#------------------------------------------------------------------------------
# Word Characters for Line Editor
#------------------------------------------------------------------------------
export WORDCHARS='*?_-.[]~=&;!#$%^(){}<>;'

