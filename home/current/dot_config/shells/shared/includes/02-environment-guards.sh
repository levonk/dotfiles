#!/usr/bin/env sh
# shellcheck shell=sh

# =============================================================================
# 02-environment-guards.sh
#
# ## Purpose
#
# - Applies environment safeguards to prevent common startup issues.
# - Unaliases `grep` to avoid interference in scripts.
# - Loads a platform detection utility for cross-platform compatibility.
# - Normalizes TTY settings to prevent shell freezes (SIGTTOU).
# =============================================================================

# Guardrails: ensure no pre-set grep alias interferes during startup
case $- in
  *i*)
    if alias grep >/dev/null 2>&1; then
        unalias grep 2>/dev/null || true
    fi
    ;;
  *) ;;
esac

# Load platform detection utility for cross-platform compatibility
PLATFORM_DETECTION_PATH="$UTIL_DIR/platform-detection.sh"
if [ -r "$PLATFORM_DETECTION_PATH" ] && [ -f "$PLATFORM_DETECTION_PATH" ]; then
    . "$PLATFORM_DETECTION_PATH" || {
        echo "Warning: Failed to source platform detection utility" >&2
    }
else
    echo "Warning: Platform detection utility not found at $PLATFORM_DETECTION_PATH" >&2
fi

# Normalize TTY settings to avoid background-write freezes (SIGTTOU)
# If a terminal has 'tostop' enabled, any background process writing to the TTY
# will be stopped by SIGTTOU. This disables 'tostop' for interactive shells.
case $- in
  *i*)
    if [ "${DOTFILES_TTY_TOSTOP:-0}" != "1" ] && [ -t 1 ] && command -v stty >/dev/null 2>&1; then
        # Only change if currently enabled
        if stty -a 2>/dev/null | grep -qw "tostop"; then
            stty -tostop 2>/dev/null || true
        fi
    fi
    ;;
  *) ;;
esac
