#!/usr/bin/env sh
# shellcheck shell=sh
#{{- includeTemplate "dot_config/ai/templates/shell/sourceable.sh.tmpl" (dict "path" .path "name" .name) -}}


# =====================================================================

## DOCKER_BUILDKIT=1 enables BuildKit, Docker’s modern build engine.
## It replaces the legacy builder with a faster, more secure,
## and more flexible system.


export DOCKER_BUILDKIT=1
