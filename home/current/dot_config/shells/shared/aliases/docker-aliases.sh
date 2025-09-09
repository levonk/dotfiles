# shellcheck shell=sh
# This file is managed by chezmoi (https://www.chezmoi.io/) and maintained at https://github.com/levonk/dotfiles
# Directory navigation aliases and functions (from legacy sharedrc and aliases)

alias dps="docker ps"  # List running containers
alias drmi="docker rmi" # Remove image
alias dlogs="docker logs -f" # Follow logs
alias dbuild="docker build -t" # Build the Docker
dstop() { docker stop "$@"; }   # Stop container(s)
drm() { docker rm "$@"; }      # Remove container(s)