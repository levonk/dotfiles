#!/usr/bin/env zsh
# Launch a fresh login zsh with verbose tracing and prompt debug, capture to log
set -eu

LOGDIR=${XDG_CACHE_HOME:-$HOME/.cache}
mkdir -p -- "$LOGDIR"
TS=$(date +%Y%m%d-%H%M%S)
LOGFILE="$LOGDIR/zsh-login-trace-$TS.log"

# Explain what we are doing
printf "Writing login trace to: %s\n" "$LOGFILE"

# Force debug for our loaders
export DEBUG_PROMPT=1
export DEBUG_SOURCING=1
export DEBUG_MODULE_LOADING=1

# Strongly prefer user's configured ZDOTDIR if set, but don't modify it here
: "${ZDOTDIR:=$HOME}"

# Build a small wrapper that enables xtrace as early as possible
WRAP=$(mktemp)
cat > "$WRAP" <<'WRAPEOF'
#!/usr/bin/env zsh
# Light wrapper: run a login + interactive shell that exits immediately after init
# This allows init (zshenv/zprofile/zshrc) to run and print DEBUG_* logs, then terminate.
setopt ERR_EXIT NO_BEEP
print -u2 -- "[[TRACE]] WRAP START: SHELL=$SHELL ZDOTDIR=${ZDOTDIR:-<unset>} XDG_CONFIG_HOME=${XDG_CONFIG_HOME:-$HOME/.config}"

# Use -l (login), -i (interactive), -c 'exit' to ensure init runs and promptly exits
exec zsh -lic 'exit'
WRAPEOF
chmod +x "$WRAP"

# Run the wrapper; capture both stdout/stderr
# Use script to provide a pseudo-tty so zsh believes it's interactive
if command -v script >/dev/null 2>&1; then
  script -q -c "$WRAP" /dev/null >"$LOGFILE" 2>&1 || true
else
  "$WRAP" >"$LOGFILE" 2>&1 || true
fi

rm -f "$WRAP"

# Print a brief tail so you can see result quickly
printf "\n--- tail of trace ---\n"
tail -n 60 -- "$LOGFILE" || true

printf "\nDone. Share the log if needed: %s\n" "$LOGFILE"
