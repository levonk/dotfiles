#!/usr/bin/env zsh
# Diagnostic script for Zsh prompt (Powerlevel10k) initialization
# Managed temporarily; safe to delete after use

set -u

banner() { printf "\n=== %s ===\n" "$1"; }

banner "Environment"
echo "USER=$USER HOST=$HOST"
echo "SHELL=$SHELL"
echo "ZDOTDIR=${ZDOTDIR:-<unset>}"
echo "XDG_CONFIG_HOME=${XDG_CONFIG_HOME:-$HOME/.config}"

echo
banner "Shell flags and options"
echo "flags($-): $-"
if whence setopt >/dev/null 2>&1; then
  setopt | grep -E '(^| )RCS($| )|NO_RCS' || echo "RCS option: not explicitly listed (default on)"
else
  echo "setopt not available (non-zsh?)"
fi

echo
banner "RC chain files"
for f in \
  "$HOME/.zshenv" \
  "${ZDOTDIR:-$HOME}/.zshrc" \
  "${ZDOTDIR:-$HOME}/entrypoint.zsh" \
  "${XDG_CONFIG_HOME:-$HOME/.config}/shells/shared/entrypointrc.sh" \
  "${XDG_CONFIG_HOME:-$HOME/.config}/shells/zsh/prompts/prompt.zsh"
do
  if [[ -e "$f" ]]; then
    printf "[ok] %s\n" "$f"
  else
    printf "[missing] %s\n" "$f"
  fi
done

echo
banner "Powerlevel10k theme location"
P10K_DIR_CUSTOM="${XDG_CONFIG_HOME:-$HOME/.config}/shells/zsh/custom/themes/powerlevel10k"
if [[ -d "$P10K_DIR_CUSTOM" ]]; then
  echo "custom dir: $P10K_DIR_CUSTOM"
  ls -1 "$P10K_DIR_CUSTOM" | sed 's/^/[p10k] /'
else
  echo "custom dir not found: $P10K_DIR_CUSTOM"
fi

echo
banner "Function path (fpath)"
print -l $fpath | sed 's/^/[fpath] /'
print -l $fpath | grep -F "$P10K_DIR_CUSTOM" >/dev/null 2>&1 && echo "[fpath] contains p10k dir" || echo "[fpath] MISSING p10k dir"

echo
banner "Powerlevel10k function presence"
if typeset -f prompt_powerlevel10k_setup >/dev/null 2>&1; then
  echo "prompt_powerlevel10k_setup: PRESENT"
else
  echo "prompt_powerlevel10k_setup: NOT PRESENT"
fi

echo
banner "Attempt to load prompt.zsh with DEBUG logs"
export DEBUG_PROMPT=1
# Source prompt loader in current shell to avoid subshell side-effects
if [[ -r "${XDG_CONFIG_HOME:-$HOME/.config}/shells/zsh/prompts/prompt.zsh" ]]; then
  source "${XDG_CONFIG_HOME:-$HOME/.config}/shells/zsh/prompts/prompt.zsh"
else
  echo "prompt.zsh not readable"
fi

if typeset -f prompt_powerlevel10k_setup >/dev/null 2>&1; then
  echo "prompt_powerlevel10k_setup: PRESENT after load"
else
  echo "prompt_powerlevel10k_setup: STILL MISSING after load"
fi

print -l $fpath | grep -F "$P10K_DIR_CUSTOM" >/dev/null 2>&1 && echo "[post] fpath contains p10k dir" || echo "[post] fpath missing p10k dir"

echo
banner "Invocation test"
if typeset -f prompt_powerlevel10k_setup >/dev/null 2>&1; then
  echo "Invoking prompt_powerlevel10k_setup ..."
  prompt_powerlevel10k_setup || true
  echo "Invocation attempted"
else
  echo "Skipping invocation; function not available"
fi

banner "Summary"
echo "ENTRY=${DOTFILES_ENTRYPOINT_RC_LOADED:-unset} PROMPT=${DOTFILES_PROMPT_SOURCED:-unset}"
echo "Done."
