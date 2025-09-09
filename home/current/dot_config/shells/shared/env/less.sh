# shellcheck shell=sh
#!/bin/bash
if [[ "" == "bash" ]]; then
  echo "ERROR: This script must be sourced, not executed."
  exit 1
fi
# shellcheck shell=bash
#------------------------------------------------------------------------------
# Less Configuration
#------------------------------------------------------------------------------
export LESS="--RAW-CONTROL-CHARS --ignore-case --quit-at-eof --quit-if-one-screen --follow-name --HILITE-SEARCH --LONG-PROMPT --squeeze-blank-lines --tabs=4"
export LESSHISTFILE="${XDG_CACHE_HOME:-$HOME/.cache}/less/lesshst"
export LESSOPEN="| /usr/bin/lesspipe %s"
