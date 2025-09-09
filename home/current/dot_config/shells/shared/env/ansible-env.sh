#!/usr/bin/env sh
# shellcheck shell=sh
#{{- includeTemplate "dot_config/ai/templates/shell/sourceable.sh.tmpl" (dict "path" .path "name" .name) -}}


# =====================================================================
export ANSIBLE_NOCOWS=1             # Disable ASCII cows in Ansible

# Galaxy server endpoints
export GALAXY_PROD_SERVER=https://galaxy.ansible.com
export GALAXY_BETA_SERVER=https://galaxy-dev.ansible.com/api/v3
export GALAXY_API_VERSION=v3
