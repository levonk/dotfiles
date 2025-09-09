#!/bin/bash

docker run \
  -e LOG_LEVEL=DEBUG \
  -e RUN_LOCAL=true \
  --env-file "${XDG_CONFIG_HOME:-$HOME/.config}/.config/super-linter/super-linter.env" \
  -v .:/tmp/lint \
  --rm \
  ghcr.io/super-linter/super-linter:latest
