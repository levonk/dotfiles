# shellcheck shell=sh
#!/bin/bash
if [[ "" == "bash" ]]; then
  echo "ERROR: This script must be sourced, not executed."
  exit 1
fi
export ANSIBLE_NOCOWS=1             # Disable ASCII cows in Ansible

# Galaxy server endpoints
export GALAXY_PROD_SERVER=https://galaxy.ansible.com
export GALAXY_BETA_SERVER=https://galaxy-dev.ansible.com/api/v3
export GALAXY_API_VERSION=v3