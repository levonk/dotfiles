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
    # Neither custom nor default locale is installed.  This is unusual, but we can't set the vars.
    echo "Neither $CUSTOM_LOCALE nor $DEFAULT_LOCALE is installed."
    echo "Please install at least one of these locales."
	echo 'sudo apt-get install locales'
    exit 1 # Exit with an error code
  fi
fi

export TZ=America/Los_Angeles     # Timezone override
