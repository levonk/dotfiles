# shellcheck shell=sh
#!/bin/bash
if [[ "" == "bash" ]]; then
  echo "ERROR: This script must be sourced, not executed."
  exit 1
fi
## DOCKER_BUILDKIT=1 enables BuildKit, Docker’s modern build engine.
## It replaces the legacy builder with a faster, more secure,
## and more flexible system.


export DOCKER_BUILDKIT=1