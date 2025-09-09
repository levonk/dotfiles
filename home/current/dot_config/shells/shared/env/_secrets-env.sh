#!/usr/bin/env sh
# shellcheck shell=sh
#{{- includeTemplate "dot_config/ai/rules/software-dev/meta/chezmoi-managed-header.md.tmpl" (dict "path" .path "name" .name) -}}

# Source all environment files from the secrets directory
# This file is managed by chezmoi - DO NOT EDIT directly

# Get the directory where this script is located
_script_dir="$(cd "$(dirname "${BASH_SOURCE[0]:-${(%):-%x}}")" && pwd -P)"
_secrets_dir="${HOME}/.secrets/secrets-env"

# Only proceed if the secrets directory exists
if [ -d "${_secrets_dir}" ]; then
  # Find all .env, .sh, .bash, and .zsh files in the secrets directory
  # and source them if they are readable and not this file
  for _file in "${_secrets_dir}"/*.{env,sh,bash,zsh}; do
    # Skip if no files match the glob pattern
    [ -e "${_file}" ] || continue
    
    # Skip if not a regular file or not readable
    [ -f "${_file}" ] && [ -r "${_file}" ] || continue
    
    # Skip files that start with a dot or underscore
    case "$(basename "${_file}")" in
      .*|_*) continue ;;
    esac
    
    # Source the file in a subshell to catch any errors
    if ! (
      # shellcheck disable=SC1090
      . "${_file}"
    ) 2>/dev/null; then
      echo "Warning: Failed to source ${_file}" >&2
    fi
  done
  
  # Clean up variables
  unset _script_dir _secrets_dir _file
fi
