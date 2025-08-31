# shellcheck shell=sh
# pnpm
export PNPM_HOME="${XDG_DATA_HOME:-$HOME/.local/share}/pnpm"

# Only add to PATH if pnpm binary exists
if [ -x "$PNPM_HOME/pnpm" ]; then
  case ":$PATH:" in
    *":$PNPM_HOME:"*) ;;
    *) export PATH="$PNPM_HOME:$PATH" ;;
  esac
fi
# pnpm end