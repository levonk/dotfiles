#!/bin/bash

# Define the custom locale
CUSTOM_LOCALE="en_US.YYYYMMDD"
DEFAULT_LOCALE="en_US.UTF-8"

# Function to check if a locale is installed
is_locale_installed() {
  locale -a | grep -q "$1"
}

# Check if the custom locale is installed
if is_locale_installed "$CUSTOM_LOCALE"; then
  # Custom locale is installed, use it
  if [ -z "${LANG}" ]; then
    export LANG="$DEFAULT_LOCALE"
  fi
  if [ -z "${LC_ALL}" ]; then
    export LC_ALL="$DEFAULT_LOCALE"
  fi
  if [ -z "${LC_TIME}" ]; then
    export LC_TIME="$CUSTOM_LOCALE"
  fi
  echo "Using custom locale: $CUSTOM_LOCALE"
else
  # Custom locale is not installed, check for default en_US.UTF-8
  if is_locale_installed "$DEFAULT_LOCALE"; then
    # Default locale is installed, use it
    if [ -z "${LANG}" ]; then
      export LANG="$DEFAULT_LOCALE"
    fi
    if [ -z "${LC_ALL}" ]; then
      export LC_ALL="$DEFAULT_LOCALE"
    fi
    echo "Using default locale: $DEFAULT_LOCALE"
  else
    # Neither custom nor default locale is installed. Fallback without failing.
    if is_locale_installed "C.UTF-8" || locale -a | grep -qi "C\\.utf8"; then
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

