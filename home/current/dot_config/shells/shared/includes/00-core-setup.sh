#!/usr/bin/env sh
# shellcheck shell=sh

# =============================================================================
# 00-core-setup.sh
#
# ## Purpose
#
# - Establishes core directory variables based on XDG standards.
# - Defines functions for tracking shell startup progress for debugging.
# =============================================================================

# Ensure XDG_CONFIG_HOME defaults to ~/.config if not set
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"

# Apply DRY principle with variables for repeated paths
SHELLS_BASE_DIR="${XDG_CONFIG_HOME}/shells"
SHELLS_SHARED_DIR="${SHELLS_BASE_DIR}/shared"
ENV_DIR="$SHELLS_SHARED_DIR/env"
UTIL_DIR="$SHELLS_SHARED_DIR/util"
ALIASES_DIR="$SHELLS_SHARED_DIR/aliases"
SHAREDRC_PATH="$SHELLS_SHARED_DIR/sharedrc.sh"

dotfiles_record_startup_token() {
    local _token="$1"

    [ -n "$_token" ] || return 0

    case ":${STARTUP_TEST_ENV:-}:" in
        *:"$_token":*)
            return 0
            ;;
    esac

    if [ -n "${STARTUP_TEST_ENV:-}" ]; then
        STARTUP_TEST_ENV="$_token:${STARTUP_TEST_ENV}"
    else
        STARTUP_TEST_ENV="$_token"
    fi

    export STARTUP_TEST_ENV
}

dotfiles_relative_token() {
    local _dir="$1"
    local _token="$_dir"

    case "$_dir" in
        "")
            printf '%s\n' ""
            return 0
            ;;
    esac

    if [ -n "${SHELLS_BASE_DIR:-}" ]; then
        case "$_dir" in
            "$SHELLS_BASE_DIR"/*)
                _token="${_dir#"$SHELLS_BASE_DIR"/}"
                ;;
        esac
    fi

    case "$_token" in
        ""|"$SHELLS_BASE_DIR")
            printf '%s\n' ""
            ;;
        *)
            printf '%s\n' "$_token"
            ;;
    esac
}

dotfiles_record_startup_dir() {
    local _dir="$1"

    [ -n "$_dir" ] || return 0

    local _token
    _token="$(dotfiles_relative_token "$_dir")"
    [ -n "$_token" ] || return 0

    dotfiles_record_startup_token "$_token"
}

# Record base directories for startup debugging
dotfiles_record_startup_dir "$ENV_DIR"
dotfiles_record_startup_dir "$UTIL_DIR"
dotfiles_record_startup_dir "$ALIASES_DIR"
dotfiles_record_startup_dir "$SHELLS_SHARED_DIR/prompts"
