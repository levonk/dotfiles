#!/usr/bin/env sh
# shellcheck shell=sh
#{{- includeTemplate "dot_config/ai/templates/shell/sourceable.sh.tmpl" (dict "path" .path "name" .name) -}}
# =====================================================================

# Define the custom locale
export DOTFILES_LOCALE_VERBOSE="${DOTFILES_LOCALE_VERBOSE:-0}"
CUSTOM_LOCALE="en_US.YYYYMMDD"
DEFAULT_LOCALE="en_US.UTF-8"

# Resolve an installed variant of a requested locale (e.g., en_US.UTF-8/en_US.utf8/en_US.UTF8)
resolve_installed_locale() {
  # $1: base pattern without worrying about case or hyphen vs none
  # Try common spellings in order of preference (POSIX: no local/arrays)
  base="$1"
  for cand in "$base.UTF-8" "$base.utf8" "$base.UTF8"; do
    installed=$(locale -a 2>/dev/null | awk '{print tolower($0)}' | grep -E "^$(echo "$cand" | tr '[:upper:]' '[:lower:]' | sed 's/\./\\./g')$")
    if [ -n "$installed" ]; then
      # Return the original casing as listed by locale -a
      locale -a 2>/dev/null | grep -i -E "^$(echo "$cand" | sed 's/\./\\./g')$" | head -n1
      return 0
    fi
  done
  return 1
}

# Case-insensitive check if a specific literal locale name exists in locale -a
is_locale_installed() {
  locale -a 2>/dev/null | grep -qi "^$(echo "$1" | sed 's/\./\\./g')$"
}

# Prefer a resolved en_US UTF-8 variant if available
RESOLVED_EN_US_LOCALE="$(resolve_installed_locale "en_US")"

# Check if the custom locale is installed
if is_locale_installed "$CUSTOM_LOCALE"; then
  # Custom locale is installed, use it for LC_TIME while keeping LANG/LC_ALL to UTF-8 en_US
  if [ -z "${LANG}" ]; then
    export LANG="${RESOLVED_EN_US_LOCALE:-$DEFAULT_LOCALE}"
  fi
  if [ -z "${LC_ALL}" ]; then
    export LC_ALL="${RESOLVED_EN_US_LOCALE:-$DEFAULT_LOCALE}"
  fi
  if [ -z "${LC_TIME}" ]; then
    export LC_TIME="$CUSTOM_LOCALE"
  fi
  if [ "${DOTFILES_LOCALE_VERBOSE}" = "1" ]; then
    case $- in *i*) echo "Using custom locale: $CUSTOM_LOCALE" ;; esac
  fi
else
  # Custom locale is not installed, check for any en_US UTF-8 variant
  if [ -n "$RESOLVED_EN_US_LOCALE" ]; then
    # A valid en_US UTF-8 variant is installed; export that exact value
    if [ -z "${LANG}" ]; then
      export LANG="$RESOLVED_EN_US_LOCALE"
    fi
    if [ -z "${LC_ALL}" ]; then
      export LC_ALL="$RESOLVED_EN_US_LOCALE"
    fi
    if [ "${DOTFILES_LOCALE_VERBOSE}" = "1" ]; then
      case $- in *i*) echo "Using default locale: $RESOLVED_EN_US_LOCALE" ;; esac
    fi
  else
    # Neither custom nor an en_US UTF-8 variant is installed. Fallback without failing.
    if is_locale_installed "C.UTF-8" || locale -a | grep -qi "^C\.utf8$"; then
      [ -z "${LANG}" ] && export LANG="C.UTF-8"
      [ -z "${LC_ALL}" ] && export LC_ALL="C.UTF-8"
      [ -z "${LC_TIME}" ] && export LC_TIME="C.UTF-8"
      if [ "${DOTFILES_LOCALE_VERBOSE}" = "1" ]; then
        case $- in *i*) echo "Warning: Falling back to locale C.UTF-8" ;; esac
      fi
    else
      [ -z "${LANG}" ] && export LANG="C"
      [ -z "${LC_ALL}" ] && export LC_ALL="C"
      [ -z "${LC_TIME}" ] && export LC_TIME="C"
      if [ "${DOTFILES_LOCALE_VERBOSE}" = "1" ]; then
        case $- in *i*) echo "Warning: Falling back to locale C" ;; esac
      fi
    fi
    if [ "${DOTFILES_LOCALE_VERBOSE}" = "1" ]; then
      case $- in *i*) echo "Tip: Install $DEFAULT_LOCALE for full i18n support (Debian/Ubuntu: sudo apt-get install locales && sudo dpkg-reconfigure locales)" ;; esac
    fi
  fi
fi

export TZ=America/Los_Angeles     # Timezone override
