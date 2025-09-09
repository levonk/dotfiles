#!/usr/bin/env sh
# shellcheck shell=sh
#{{- includeTemplate "dot_config/ai/snippets/shell/sourceable.sh.tmpl" (dict "path" .path "name" .name) -}}


# =====================================================================
# Directory navigation aliases and functions (from legacy sharedrc and aliases)

alias dps="docker ps"  # List running containers
alias drmi="docker rmi" # Remove image
alias dlogs="docker logs -f" # Follow logs
alias dbuild="docker build -t" # Build the Docker
dstop() { docker stop "$@"; }   # Stop container(s)
drm() { docker rm "$@"; }      # Remove container(s)
