#!/usr/bin/env sh
# shellcheck shell=bash
#{{- includeTemplate "dot_config/ai/templates/shell/sourceable.sh.tmpl" (dict "path" .path "name" .name) -}}


# =====================================================================
# Bash Key Bindings
# =====================================================================

# Enable vi mode, starts in insert mode
set -o vi

# Bash doesn't directly support history substring search on arrow keys like zsh.
# We can approximate it using readline variables and bind.

# Set readline variables to use history substring search on up/down arrows
bind '"\e[A": history-search-backward'
bind '"\e[B": history-search-forward'

# Ctrl+a goes to the beginning of the line
bind '^a:beginning-of-line'
# Ctrl+e goes to the end of the line
bind '^e:end-of-line'
# Ctrl+u deletes from current cursor to start of line
bind '^u:unix-line-discard'
# Ctrl+k deletes from current cursor to end of line
bind '^k:kill-line'

# =====================================================================
# End of Bash Key Bindings
# =====================================================================
