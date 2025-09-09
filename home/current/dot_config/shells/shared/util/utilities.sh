# shellcheck shell=sh
#!/bin/bash
if [[ "" == "bash" ]]; then
  echo "ERROR: This script must be sourced, not executed."
  exit 1
fi
# This file is managed by chezmoi (https://www.chezmoi.io/) and maintained at https://github.com/levonk/dotfiles
# Utility functions (from sharedrc and aliases)

# xml formatter
xmlfmt() {
    xmllint -format -recover "$1" >| "$1"
}

# Apache Maven via docker (official image, maintained)
mvnd() {
    # Use official Maven image with OpenJDK 17 (recommended)
    docker run --rm -it \
        -v "${HOME}/.m2:/root/.m2" \
        -v "$(pwd):/workdir" \
        -w /workdir \
        maven:3.8.3-openjdk-17 "$@"
}

# Amazon EC2 metadata query
cloud-data() {
    curl -f -s "http://169.254.169.254/latest/meta-data/$1"
    echo
}

# Fun/utility: fortune and xmlstarlet
EXE_FORTUNE=/usr/games/fortune
if [ -f $EXE_FORTUNE ]; then
    $EXE_FORTUNE -ac
fi

EXE_XMLSTARLET=/usr/bin/xmlstarlet
if [ -f $EXE_XMLSTARLET ]; then
    $EXE_XMLSTARLET sel --net -t -m '/rss/channel/item/description' -v '.' 'http://dictionary.reference.com/wordoftheday/wotd.rss'
fi
