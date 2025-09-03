# shellcheck shell=sh
# bun
export BUN_INSTALL="${XDG_DATA_HOME:-$HOME/.local/share}/bun"
BUN_BIN="$BUN_INSTALL/bin"

if [ -x "$BUN_BIN/bun" ]; then
  case ":$PATH:" in
    *":$BUN_BIN:"*) ;;
    *) export PATH="$BUN_BIN:$PATH" ;;
  esac
fi

# Warn if another Bun install exists under ~/.bun but BUN_INSTALL points elsewhere
if [ -x "$HOME/.bun/bin/bun" ] && [ "${BUN_INSTALL%/}" != "${HOME%/}/.bun" ]; then
  printf 'Warning: Bun also present at %s; BUN_INSTALL=%s (PATH uses %s)\n' "$HOME/.bun" "$BUN_INSTALL" "$BUN_INSTALL/bin" >&2
fi
