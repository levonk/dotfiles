#!/usr/bin/env bash
#
# git-status-digest.sh — Auditable repository state snapshot
#
# Purpose:
#   Print an easy-to-scan digest of the current Git repo state to verify
#   environment before taking actions like committing or releasing.
#   Read-only; does not mutate repo state.
#
# Usage:
#   scripts/git-status-digest.sh [identify|assert-clean] [--all] [--fail-if-dirty] [--preflight-health] [--suggest-commits] [--summary-new N]
#
# Modes (positional; default: assert-clean):
#   identify       Print a full digest to INSPECT changes and plan grouped commits.
#   assert-clean   Fast check; quiet success (no output) when clean; if dirty, exit non-zero and print a concise summary.
#
# Default mode: assert-clean
#   - Non-verbose on success; concise summary on failure (porcelain, staged, modified, untracked; ahead count).
#
# Examples:
#   # Inspect changes to plan grouped commits
#   executable_git-status-digest.sh identify
#
#   # Gate before declaring repo clean (non-verbose success)
#   executable_git-status-digest.sh assert-clean
#
# Flags:
#   --all               Include extra sections (stashes, recent commits)
#   --fail-if-dirty     Exit non-zero if untracked/staged/modified changes exist or branch is ahead of upstream
#   --preflight-health  Run repo health script if available (read-only)
#   --suggest-commits   Print suggested grouped commit commands (read-only)
#   --summary-new N     Show last N commits with stats (read-only)
#
# Steps:
#   1. Ensure all editor buffers are saved to disk, if not save them
#   2. Ensure we are in a git work tree, if not exit non-zero
#   3. Ensure required tool(s) exist and we have the rights to those tools before any usage, if not exit non-zero
#   4. Parse arguments
#   5. Resolve paths and basics
#   6. Ensure git config user.name and user.email are set, if not
#		1. if the directory above the project directory is `levonk`, if it is then run `git config user.name "levonk" && git config user.email "277861+levonk@users.noreply.github.com"`
#   7. Check `git config --get commit.gpgsign`, if not set print `[warn] commit.gpgsign is not set, not attempting to sign commits`
#   8. Print digest:
	# 1. Print `last 5 commits`
	# 2. Print `name`, `email`, `commit.gpgsign`, `gpg.program`, `gpg.format`, `gpg.ssh.program`, `gpg.x509.program`, `signingkey`
	# 3. Print `staged (index)`
	# 4. Print `modified (workspace)`
	# 5. Print `submodules`
	# 6. Print `worktrees`
	# 7. Print `in-progress ops`
	# 8. Print `upstream delta`
	# 9. Print `stashes`
	# 10. Print `untracked`
	# 11. Print `porcelain`
	# 12. concisely Print `cwd`, `repo`, `branch`, `upstream`
set -euo pipefail

# PATH guard for ~/.local/bin (non-destructive; avoids duplicates)
case ":$PATH:" in *":$HOME/.local/bin:"*) : ;; *) export PATH="$HOME/.local/bin:$PATH" ;; esac

# Small helpers
command_exists() { command -v "$1" >/dev/null 2>&1; }

color() { [ -t 1 ] && printf "\033[%sm" "$1" || true; }
cecho() { local c="$1"; shift; color "$c"; printf "%s\n" "$*"; color 0; }

# Ensure required tool(s) exist before any usage
if ! command_exists git; then
  cecho 31 "[digest] 'git' not found in PATH"
  exit 127
fi

# Ensure we are in a git work tree
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  cecho 31 "[digest] Not inside a git work tree"
  exit 1
fi

MODE="assert-clean"   # default behavior per workflow
INCLUDE_ALL=0
FAIL_IF_DIRTY=0
DO_PREFLIGHT=0
DO_SUGGEST=0
SUMMARY_N=0

# Argument parser
while [ $# -gt 0 ]; do
  case "$1" in
    --all) INCLUDE_ALL=1 ;;
    --fail-if-dirty) FAIL_IF_DIRTY=1 ;;
    --preflight-health) DO_PREFLIGHT=1 ;;
    --suggest-commits) DO_SUGGEST=1 ;;
    --summary-new)
      shift || true
      SUMMARY_N=${1:-0}
      ;;
    -h|--help)
      sed -n '1,80p' "$0"; exit 0 ;;
    identify) MODE="identify" ;;
    assert-clean) MODE="assert-clean" ;;
    *) printf "warn: unknown flag/arg: %s\n" "$1" >&2 ;;
  esac
  shift || true
done

# Resolve paths and basics
CWD=$(pwd)
ROOT=$(git rev-parse --show-toplevel 2>/dev/null || echo "?")
BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "?")
UPSTREAM=$(git rev-parse --abbrev-ref --symbolic-full-name @{u} 2>/dev/null || true)

# Fast-path: assert-clean mode (default). Quiet success; concise summary on failure.
if [ "$MODE" = "assert-clean" ] && [ "$FAIL_IF_DIRTY" -eq 0 ]; then
  PORC=$(git status --untracked-files=all --porcelain)
  S=$(git diff --cached --name-status)
  M=$(git diff --name-status)
  U=$(git ls-files --others --exclude-standard)
  ahead=0
  if [ -n "${UPSTREAM:-}" ]; then
    lr=$(git rev-list --left-right --count "$UPSTREAM"...HEAD 2>/dev/null || echo "0\t0")
    ahead=$(echo "$lr" | awk '{print $2}')
  fi
  if [ -z "$PORC$S$M$U" ] && [ "${ahead}" -eq 0 ]; then
    exit 0
  fi
  # Dirty: print concise summary and exit non-zero
  printf "[error] repo not clean or has unpushed commits (ahead=%s)\n" "${ahead}"
  printf "cwd: %s\nrepo: %s\nbranch: %s\nupstream: %s\n" "$CWD" "$ROOT" "$BRANCH" "${UPSTREAM:-<none>}"
  printf "\n-- porcelain --\n"; printf "%s\n" "$PORC"
  printf "\n-- staged (index) --\n"; printf "%s\n" "$S"
  printf "\n-- modified (workspace) --\n"; printf "%s\n" "$M"
  printf "\n-- untracked --\n"; printf "%s\n" "$U"
  exit 2
fi

printf "== Git Status Digest ==\n"
printf "cwd:      %s\n" "$CWD"
printf "repo:     %s\n" "$ROOT"
printf "branch:   %s\n" "$BRANCH"
printf "upstream: %s\n" "${UPSTREAM:-<none>}"

# Identity and signing configuration
printf "\n-- identity & signing --\n"
NAME=$(git config --get user.name || true)
EMAIL=$(git config --get user.email || true)
GPGSIGN=$(git config --get commit.gpgsign || true)
GPGPROG=$(git config --get gpg.program || true)
GPGFMT=$(git config --get gpg.format || true)
GPGSSH=$(git config --get gpg.ssh.program || true)
GPGX509=$(git config --get gpg.x509.program || true)
SIGNINGKEY=$(git config --get user.signingkey || true)

# Normalize signing intent
case "${GPGSIGN:-}" in
  true|1|yes|on) WILL_SIGN=1 ;;
  *)             WILL_SIGN=0 ;;
esac

printf "name:        %s\n" "${NAME:-<missing>}"
printf "email:       %s\n" "${EMAIL:-<missing>}"
printf "commit.gpgsign: %s\n" "${GPGSIGN:-<unset>}"
printf "gpg.program: %s\n" "${GPGPROG:-<unset>}"
printf "gpg.format:  %s\n" "${GPGFMT:-<unset>}"
printf "gpg.ssh.program: %s\n" "${GPGSSH:-<unset>}"
printf "gpg.x509.program: %s\n" "${GPGX509:-<unset>}"
printf "signingkey:  %s\n" "${SIGNINGKEY:-<unset>}"

# Abort early if identity is incomplete
if [ -z "${NAME:-}" ] || [ -z "${EMAIL:-}" ]; then
  cecho 31 "[error] missing git identity (user.name or user.email)"
  exit 3
fi

# Warn if signing is enabled but signer tool isn't available
if [ "$WILL_SIGN" -eq 1 ]; then
  case "${GPGFMT:-openpgp}" in
    ssh)
      EFFECTIVE_SSH="${GPGSSH:-ssh-keygen}"
      if ! command_exists "$EFFECTIVE_SSH"; then
        cecho 33 "[warn] signing enabled (ssh) but '$EFFECTIVE_SSH' not found; commits may fail"
      fi
      if [ -z "${SIGNINGKEY:-}" ]; then
        cecho 33 "[warn] signing enabled (ssh) but user.signingkey not set"
      fi
      ;;
    x509)
      EFFECTIVE_X509="${GPGX509:-gpgsm}"
      if ! command_exists "$EFFECTIVE_X509"; then
        cecho 33 "[warn] signing enabled (x509) but '$EFFECTIVE_X509' not found; commits may fail"
      fi
      ;;
    *)
      # OpenPGP (default)
      EFFECTIVE_GPG="${GPGPROG:-gpg}"
      if ! command_exists "$EFFECTIVE_GPG"; then
        cecho 33 "[warn] commit.gpgsign is on but '$EFFECTIVE_GPG' not found; commits may fail"
      fi
      ;;
  esac
fi

# Porcelain status
printf "\n-- porcelain --\n"
git status --untracked-files=all --porcelain || true

# Staged / Unstaged / Untracked breakdown
printf "\n-- staged (index) --\n"
(git diff --cached --name-status || true)
printf "\n-- modified (workspace) --\n"
(git diff --name-status || true)
printf "\n-- untracked --\n"
(git ls-files --others --exclude-standard || true)

# Submodules and worktrees
printf "\n-- submodules --\n"
(git submodule status 2>/dev/null || echo "<none>")
printf "\n-- worktrees --\n"
(git worktree list 2>/dev/null || echo "<none>")

# In-progress operations
printf "\n-- in-progress ops --\n"
GIT_DIR=$(git rev-parse --git-dir)
ops=()
[ -f "$GIT_DIR/MERGE_HEAD" ] && ops+=(merge)
[ -d "$GIT_DIR/rebase-apply" ] && ops+=(rebase-apply)
[ -d "$GIT_DIR/rebase-merge" ] && ops+=(rebase-merge)
[ -f "$GIT_DIR/CHERRY_PICK_HEAD" ] && ops+=(cherry-pick)
[ -f "$GIT_DIR/REVERT_HEAD" ] && ops+=(revert)
if [ ${#ops[@]} -gt 0 ]; then
  printf "%s\n" "${ops[*]}"
else
  echo "<none>"
fi

# Ahead/behind relative to upstream
if [ -n "${UPSTREAM:-}" ]; then
  lr=$(git rev-list --left-right --count "$UPSTREAM"...HEAD 2>/dev/null || echo "0	0")
  behind=$(echo "$lr" | awk '{print $1}')
  ahead=$(echo "$lr" | awk '{print $2}')
  printf "\n-- upstream delta --\n"
  printf "ahead:  %s\nbehind: %s\n" "$ahead" "$behind"
fi

if [ "$FAIL_IF_DIRTY" -eq 1 ]; then
  # Git cleanliness gate per shell-verify
  U=$(git ls-files --others --exclude-standard)
  S=$(git diff --cached --name-status)
  M=$(git diff --name-status)
  AHEAD=${ahead:-0}
  if [ -n "$U$S$M" ] || { [ -n "${UPSTREAM:-}" ] && [ "${AHEAD}" -gt 0 ]; }; then
    printf "\n[error] repo not clean or has unpushed commits (ahead=%s)\n" "${AHEAD}"
    printf "Status summary (porcelain):\n"
    git status -s -uall || true
    exit 2
  fi
fi

if [ "$INCLUDE_ALL" -eq 1 ]; then
  printf "\n-- stashes --\n"
  (git stash list || true)
  printf "\n-- last 5 commits --\n"
  (git log -n 5 --oneline --decorate || true)
fi

if [ "$DO_PREFLIGHT" -eq 1 ]; then
  printf "\n-- preflight health (scripts/repo-health.sh --quick) --\n"
  if [ "${GSD_SKIP_PREFLIGHT:-0}" = "1" ]; then
    echo "[info] skipping preflight (GSD_SKIP_PREFLIGHT=1)"
  elif [ -x "$ROOT/scripts/repo-health.sh" ]; then
    if command_exists timeout; then
      TO=${GSD_PREFLIGHT_TIMEOUT_SECS:-30}
      (cd "$ROOT" && timeout "${TO}"s "$ROOT/scripts/repo-health.sh" --quick) || true
    else
      (cd "$ROOT" && "$ROOT/scripts/repo-health.sh" --quick) || true
    fi
  else
    echo "[info] repo-health.sh not found or not executable; skipping"
  fi
fi

if [ "$DO_SUGGEST" -eq 1 ]; then
  printf "\n-- suggested commit groups (dry-run) --\n"
  # Collect changes from porcelain to group by top-level scope
  PORC=$(git status --untracked-files=all --porcelain)
  if [ -z "$PORC" ]; then
    echo "[info] no changes to suggest commits for"
  else
    # Build a list of files (2nd column of porcelain output)
    FILES=$(printf "%s\n" "$PORC" | awk '{sub(/^.../ , "", $0); print $0}')
    # Group by scope heuristics
    group_scope() {
      case "$1" in
        scripts/tests/*) echo tests ;;
        scripts/*) echo scripts ;;
        tests/*) echo tests ;;
        home/current/dot_config/shells/*) echo shells ;;
        internal-docs/*) echo docs ;;
        home/*) echo home ;;
        *) echo misc ;;
      esac
    }
    # Create temp files per scope
    tmpdir=$(mktemp -d)
    echo "$FILES" | while IFS= read -r f; do
      s=$(group_scope "$f")
      printf "%s\n" "$f" >> "$tmpdir/$s.list"
    done
    for list in "$tmpdir"/*.list; do
      [ -f "$list" ] || continue
      scope=$(basename "$list" .list)
      echo "\n# scope: $scope"
      echo "git add \"$(tr '\n' ' ' <"$list" | sed 's/ $//')\""
      # Suggest a conventional commit title template
      case "$scope" in
        scripts) title="chore(scripts): update helper scripts" ;;
        tests) title="test: update tests" ;;
        shells) title="feat(shells): config or utils change" ;;
        docs) title="docs: update internal docs" ;;
        home) title="feat(home): dotfiles updates" ;;
        *) title="chore(${scope}): updates" ;;
      esac
      echo "git commit -m \"$title\" -m \"Describe changes; why needed.\""
    done
    rm -rf "$tmpdir"
  fi
fi

if [ "$SUMMARY_N" -gt 0 ]; then
  printf "\n-- recent commits (last %s) --\n" "$SUMMARY_N"
  git log -n "$SUMMARY_N" --oneline --decorate --stat || true
fi

printf "\n== End Digest ==\n"
