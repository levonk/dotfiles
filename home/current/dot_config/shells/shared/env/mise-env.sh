#!/usr/bin/env sh
# shellcheck shell=sh
#{{- includeTemplate "dot_config/ai/templates/shell/sourceable.sh.tmpl" (dict "path" .path "name" .name) -}}
# =====================================================================

_MISE_SHIMS="$HOME/.local/share/mise/shims"

case ":${PATH}:" in
    *:"$_MISE_SHIMS":*)
		echo "Debug: Mise shims already in PATH" >&2
        ;;
    *)
		echo "Debug: Prepending Mise shims to PATH" >&2
        # Prepending path in case a system-installed binary needs to be overridden
        export PATH="$_MISE_SHIMS:$PATH"
        ;;
esac
