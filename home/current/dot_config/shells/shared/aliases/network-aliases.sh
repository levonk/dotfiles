#!/usr/bin/env sh
# shellcheck shell=sh
#{{- includeTemplate "dot_config/ai/templates/shell/sourceable.sh.tmpl" (dict "path" .path "name" .name) -}}


# =====================================================================
# Network and utility aliases (from legacy sharedrc)

# Get the remote IP address
alias myip="dig +short myip.opendns.com @resolver1.opendns.com"
