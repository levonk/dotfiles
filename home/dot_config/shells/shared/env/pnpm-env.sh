# pnpm
export PNPM_HOME="/home/micro/.local/share/pnpm"

# Only add to PATH if pnpm binary exists
if [ -f "$PNPM_HOME/pnpm" ]; then
  case ":$PATH:" in
    *":$PNPM_HOME:"*) ;;
    *) export PATH="$PNPM_HOME:$PATH" ;;
  esac
fi
# pnpm end