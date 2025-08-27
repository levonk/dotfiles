#!/bin/bash

# Define the custom locale
CUSTOM_LOCALE="en_US.YYYYMMDD"
DEFAULT_LOCALE="en_US.UTF-8"

# Resolve an installed variant of a requested locale (e.g., en_US.UTF-8/en_US.utf8/en_US.UTF8)
resolve_installed_locale() {
  # $1: base pattern without worrying about case or hyphen vs none
  # Try common spellings in order of preference
  local base="$1"
  local candidates=(
    "$base.UTF-8"
    "$base.utf8"
    "$base.UTF8"
  )
  local installed
  for cand in "${candidates[@]}"; do
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
  echo "Using custom locale: $CUSTOM_LOCALE"
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
    echo "Using default locale: $RESOLVED_EN_US_LOCALE"
  else
    # Neither custom nor an en_US UTF-8 variant is installed. Fallback without failing.
    if is_locale_installed "C.UTF-8" || locale -a | grep -qi "^C\.utf8$"; then
      [ -z "${LANG}" ] && export LANG="C.UTF-8"
      [ -z "${LC_ALL}" ] && export LC_ALL="C.UTF-8"
      [ -z "${LC_TIME}" ] && export LC_TIME="C.UTF-8"
      echo "Warning: Falling back to locale C.UTF-8"
    else
      [ -z "${LANG}" ] && export LANG="C"
      [ -z "${LC_ALL}" ] && export LC_ALL="C"
      [ -z "${LC_TIME}" ] && export LC_TIME="C"
      echo "Warning: Falling back to locale C"
    fi
    echo "Tip: Install $DEFAULT_LOCALE for full i18n support (Debian/Ubuntu: sudo apt-get install locales && sudo dpkg-reconfigure locales)"
  fi
fi

export TZ=America/Los_Angeles     # Timezone override

