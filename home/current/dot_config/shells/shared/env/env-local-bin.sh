#!/usr/bin/env sh
# shellcheck shell=sh
#{{- includeTemplate "dot_config/ai/templates/shell/sourceable.sh.tmpl" (dict "path" .path "name" .name) -}}


# =====================================================================
# add binaries to PATH if they aren't added yet
# affix colons on either side of $PATH to simplify matching
case ":${PATH}:" in
    *:"$XDG_BIN_HOME":*)
        ;;
    *)
        # Prepending path in case a system-installed binary needs to be overridden
        export PATH="$XDG_BIN_HOME:$PATH"
        ;;
esac
