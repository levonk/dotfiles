#!/usr/bin/env sh
printf "__STARTUP_VARS__BUN_INSTALL=%s|PATH=%s|USER=%s|SHELL=%s|STARTUP_TEST_ENV=%s\n" "${BUN_INSTALL-}" "${PATH-}" "$1" "$2" "${STARTUP_TEST_ENV-}"
