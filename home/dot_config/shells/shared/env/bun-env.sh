# bun
export BUN_INSTALL="${XDG_DATA_HOME:-$HOME/.local/share}/bun"
BUN_BIN="$BUN_INSTALL/bin"

if [ -x "$BUN_BIN/bun" ]; then
  case ":$PATH:" in
    *":$BUN_BIN:"*) ;;
    *) export PATH="$BUN_BIN:$PATH" ;;
  esac
fi
