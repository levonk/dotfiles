#!/usr/bin/env sh
#
# git-createnewfirstcommit.sh
#
# Create a new empty root commit and rebase the branch so that this
# empty commit becomes the first commit in history. This enables
# clean interactive rebases where the original first commit can be
# squashed or edited.
#
# Safe implementation: uses `git commit-tree` to create an empty commit
# without touching the working tree or index. Avoids risky orphan/clean
# steps that delete files.
#
# Usage:
#   git-createnewfirstcommit.sh [--target-branch BRANCH]
#                               [--message MSG]
#                               [--rebase-merges]
#                               [--create-branch NAME]
#                               [--remote-check REMOTE[/BRANCH]]
#                               [--signoff]
#                               [--gpg-sign [KEYID]]
#                               [--yes]
#                               [--dry-run]
#                               [--force]
#                               [--non-interactive]
#                               [--pre-push|--no-pre-push]
#                               [--auto-push]
#                               [--backup-tag NAME|--no-backup]
#                               [--no-gpg-sign|--require-gpg]
#                               [--no-fetch]
#                               [--allow-protected]
#   git-createnewfirstcommit.sh --help
#
# Options:
#   --target-branch BRANCH  Branch to rewrite (default: current branch)
#   --message MSG           Message for the new empty root commit
#                           (default: "Initial empty commit")
#   --rebase-merges         Preserve merge commits during the rebase
#   --create-branch NAME    Operate on a new branch created from target
#                           (deletes existing NAME if --force is given)
#   --remote-check REF      Abort if remote has commits you don't have.
#                           REF may be "origin" (uses origin/BRANCH) or
#                           "origin/branch" for explicit remote ref.
#   --signoff               Append a Signed-off-by trailer to the message
#   --gpg-sign [KEYID]      GPG-sign the new root commit (optional key id). Default: enabled
#   --yes                   Do not prompt for confirmation
#   --dry-run               Print planned commands, do not execute
#   --force                 Skip clean working tree check
#   --non-interactive       Equivalent to: --yes --force --remote-check origin
#   --pre-push              Push the target branch to its upstream BEFORE rewrite (default: on)
#   --no-pre-push           Disable pre-push
#   --auto-push             Force-push the rewritten branch AFTER rewrite
#   --backup-tag NAME       Create an annotated tag before rewrite (default name
#                           backup/<branch>/<YYYYmmdd-HHMMSS>-newroot)
#   --no-backup             Skip creating the backup tag
#   --no-gpg-sign           Do not GPG-sign the new root commit
#   --require-gpg           Fail if signing is not possible (no fallback). Otherwise
#                           the script prompts to proceed unsigned (or auto-accepts
#                           unsigned if --yes/--non-interactive)
#   --no-fetch              Skip initial `git fetch --all --prune`
#   --allow-protected       Allow rewriting protected branches like main/master
#   -h, --help              Show this help
#
# Notes:
# - This REWRITES HISTORY of the target branch. You may need to force-push.
# - Ensure all collaborators are aware before proceeding.
# - Requires Git 2.x with commit-tree available (standard).
# - GPG signing: signing is ON by default. If signing fails and --require-gpg is not set,
#   you will be prompted to continue unsigned; with --yes, it continues unsigned automatically.

set -eu

usage() {
  sed -n '1,80p' "$0" | sed -n '1,80p' | awk 'BEGIN{p=0} /^#!/{p=1} p{print} '
}

log() { printf '[INFO] %s\n' "$*"; }
warn() { printf '[WARN] %s\n' "$*" 1>&2; }
err()  { printf '[ERROR] %s\n' "$*" 1>&2; }

DRY_RUN=false
YES=false
REBASE_MERGES=false
FORCE=false
TARGET_BRANCH=""
MSG="Initial empty commit"
CREATE_BRANCH=""
REMOTE_CHECK_REF=""
SIGNOFF=false
GPG_SIGN="yes"
NON_INTERACTIVE=false
PRE_PUSH=true
AUTO_PUSH=false
BACKUP=true
BACKUP_TAG=""
NO_FETCH=false
REQUIRE_GPG=false
ALLOW_PROTECTED=false
PROTECTED_BRANCHES="main master"

while [ $# -gt 0 ]; do
  case "$1" in
    --target-branch) TARGET_BRANCH="$2"; shift 2;;
    --message) MSG="$2"; shift 2;;
    --rebase-merges) REBASE_MERGES=true; shift;;
    --create-branch) CREATE_BRANCH="$2"; shift 2;;
    --remote-check) REMOTE_CHECK_REF="$2"; shift 2;;
    --signoff) SIGNOFF=true; shift;;
    --gpg-sign)
      # optional KEYID
      if [ $# -ge 2 ] && [ "${2#--}" = "$2" ]; then
        GPG_SIGN="$2"; shift 2
      else
        GPG_SIGN="yes"; shift
      fi
      ;;
    --no-gpg-sign) GPG_SIGN=""; shift;;
    --require-gpg) REQUIRE_GPG=true; shift;;
    --yes) YES=true; shift;;
    --dry-run) DRY_RUN=true; shift;;
    --force) FORCE=true; shift;;
    --non-interactive) NON_INTERACTIVE=true; YES=true; FORCE=true; [ -z "$REMOTE_CHECK_REF" ] && REMOTE_CHECK_REF="origin"; shift;;
    --pre-push) PRE_PUSH=true; shift;;
    --no-pre-push) PRE_PUSH=false; shift;;
    --auto-push) AUTO_PUSH=true; shift;;
    --backup-tag) BACKUP_TAG="$2"; shift 2;;
    --no-backup) BACKUP=false; shift;;
    --no-fetch) NO_FETCH=true; shift;;
    --allow-protected) ALLOW_PROTECTED=true; shift;;
    -h|--help) usage; exit 0;;
    *) err "Unknown argument: $1"; usage; exit 2;;
  esac
done

# Ensure we are in a Git repo
if ! git rev-parse --git-dir >/dev/null 2>&1; then
  err "Not a git repository"
  exit 1
fi

# Initial safety fetch (default on)
if ! $NO_FETCH; then
  if $DRY_RUN; then
    warn "Dry-run: skipping fetch --all --prune"
  else
    log "Fetching remotes (git fetch --all --prune)"
    git fetch --all --prune || warn "Fetch encountered errors; continue with caution"
  fi
fi

# Determine current branch if none specified
if [ -z "$TARGET_BRANCH" ]; then
  TARGET_BRANCH=$(git rev-parse --abbrev-ref HEAD)
  if [ "$TARGET_BRANCH" = "HEAD" ]; then
    err "Detached HEAD; specify --target-branch explicitly"
    exit 1
  fi
fi

# Verify branch exists
if ! git show-ref --verify --quiet "refs/heads/$TARGET_BRANCH"; then
  err "Branch not found: $TARGET_BRANCH"
  exit 1
fi

# Guard protected branches unless explicitly allowed
for pb in $PROTECTED_BRANCHES; do
  if [ "$TARGET_BRANCH" = "$pb" ] && ! $ALLOW_PROTECTED; then
    err "Branch '$TARGET_BRANCH' appears protected. Refusing to rewrite without --allow-protected."
    exit 1
  fi
done

# If creating a new branch, prepare it now (will switch later)
if [ -n "$CREATE_BRANCH" ]; then
  if git show-ref --verify --quiet "refs/heads/$CREATE_BRANCH"; then
    if $FORCE; then
      warn "Branch $CREATE_BRANCH exists; deleting due to --force"
      git branch -D "$CREATE_BRANCH"
    else
      err "Branch $CREATE_BRANCH already exists (use --force to overwrite)"
      exit 1
    fi
  fi
  # Create from target branch tip
  git branch "$CREATE_BRANCH" "$TARGET_BRANCH"
  TARGET_BRANCH="$CREATE_BRANCH"
fi

# Check clean working tree unless forced
if ! $FORCE; then
  if [ -n "$(git status --porcelain)" ]; then
    err "Working tree not clean. Commit/stash changes or use --force."
    exit 1
  fi
fi

CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)

# Build the commands
EMPTY_TREE_CMD='git hash-object -t tree /dev/null'
COMMIT_TREE_CMD='git commit-tree'

# Create empty tree hash
EMPTY_TREE=$(sh -c "$EMPTY_TREE_CMD")

# Build commit message (apply signoff if requested)
FINAL_MSG="$MSG"
if $SIGNOFF; then
  # Derive signoff from git config
  name=$(git config user.name || true)
  email=$(git config user.email || true)
  if [ -n "$name" ] && [ -n "$email" ]; then
    FINAL_MSG="$FINAL_MSG

Signed-off-by: $name <$email>"
  else
    warn "--signoff requested but user.name/email not set; skipping trailer"
  fi
fi

# Create empty commit with no parents using commit-tree (optionally GPG sign)
if [ -n "$GPG_SIGN" ]; then
  if [ "$GPG_SIGN" != "yes" ]; then
    if NEWROOT=$(printf %s "$FINAL_MSG" | $COMMIT_TREE_CMD -S"$GPG_SIGN" "$EMPTY_TREE" 2>/dev/null); then :; else
      if $REQUIRE_GPG; then
        err "GPG sign with key '$GPG_SIGN' failed and --require-gpg is set"
        exit 1
      fi
      if $YES; then
        warn "GPG signing failed; proceeding with unsigned commit due to --yes"
        NEWROOT=$(printf %s "$FINAL_MSG" | $COMMIT_TREE_CMD "$EMPTY_TREE")
      else
        printf '%s ' "GPG signing failed for key '$GPG_SIGN'. Proceed with UNSIGNED commit? [y/N]:"; read gpg_ans || gpg_ans=""
        case "$gpg_ans" in
          y|Y|yes|YES)
            NEWROOT=$(printf %s "$FINAL_MSG" | $COMMIT_TREE_CMD "$EMPTY_TREE")
            ;;
          *)
            err "Aborted due to GPG signing failure"
            exit 1
            ;;
        esac
      fi
    fi
  else
    if NEWROOT=$(printf %s "$FINAL_MSG" | $COMMIT_TREE_CMD -S "$EMPTY_TREE" 2>/dev/null); then :; else
      if $REQUIRE_GPG; then
        err "GPG sign failed and --require-gpg is set"
        exit 1
      fi
      if $YES; then
        warn "GPG signing failed; proceeding with unsigned commit due to --yes"
        NEWROOT=$(printf %s "$FINAL_MSG" | $COMMIT_TREE_CMD "$EMPTY_TREE")
      else
        printf '%s ' "GPG signing failed. Proceed with UNSIGNED commit? [y/N]:"; read gpg_ans || gpg_ans=""
        case "$gpg_ans" in
          y|Y|yes|YES)
            NEWROOT=$(printf %s "$FINAL_MSG" | $COMMIT_TREE_CMD "$EMPTY_TREE")
            ;;
          *)
            err "Aborted due to GPG signing failure"
            exit 1
            ;;
        esac
      fi
    fi
  fi
else
  NEWROOT=$(printf %s "$FINAL_MSG" | $COMMIT_TREE_CMD "$EMPTY_TREE")
fi

# Compose rebase command
REBASE_CMD="git checkout $TARGET_BRANCH && git rebase --onto $NEWROOT --root"
if $REBASE_MERGES; then
  REBASE_CMD="$REBASE_CMD --rebase-merges"
fi

# Optional remote safety check (moved to correct location)
if [ -n "$REMOTE_CHECK_REF" ]; then
  ref="$REMOTE_CHECK_REF"
  case "$ref" in
    */*) : ;; # remote/branch provided
    *) ref="$ref/$TARGET_BRANCH";;
  esac
  # Ensure we have the remote ref in refs/remotes; otherwise try to fetch it
  if ! git show-ref --verify --quiet "refs/remotes/$ref"; then
    warn "Remote ref $ref not found locally; attempting to fetch"
    if $DRY_RUN; then
      warn "Dry-run: skipping fetch of $ref"
    else
      git fetch "${ref%%/*}" "${ref#*/}:refs/remotes/$ref" || true
    fi
  fi
  if git show-ref --verify --quiet "refs/remotes/$ref"; then
    ahead_behind=$(git rev-list --left-right --count "refs/heads/$TARGET_BRANCH...refs/remotes/$ref")
    left=$(printf %s "$ahead_behind" | awk '{print $1}')
    right=$(printf %s "$ahead_behind" | awk '{print $2}')
    if [ "$right" -gt 0 ]; then
      err "Remote $ref has $right commits you don't have. Ensure teammates have pushed and you have fetched/rebased before proceeding."
      exit 1
    fi
  else
    warn "Could not verify remote ref $ref; proceeding without remote check"
  fi
fi

# Optional pre-push of current target branch
if $PRE_PUSH; then
  upstream=$(git rev-parse --abbrev-ref --symbolic-full-name "$TARGET_BRANCH@{upstream}" 2>/dev/null || true)
  if [ -n "$upstream" ]; then
    run "git push"
  else
    warn "No upstream configured for $TARGET_BRANCH; skipping pre-push"
  fi
fi

# Optional backup tag before rewrite
if $BACKUP; then
  if [ -z "$BACKUP_TAG" ]; then
    ts=$(date +%Y%m%d-%H%M%S)
    BACKUP_TAG="backup/$TARGET_BRANCH/$ts-newroot"
  fi
  run "git tag -a '$BACKUP_TAG' -m 'Backup before inserting new root commit on $TARGET_BRANCH' 'refs/heads/$TARGET_BRANCH'"
fi

confirm() {
  if $YES; then return 0; fi
  printf '%s\n' "About to rewrite history of branch '$TARGET_BRANCH' by inserting a new empty root commit.";
  printf '%s\n' "This is equivalent to:"
  printf '  %s\n' "$REBASE_CMD"
  printf '%s\n' "Recommendations:"
  printf '  - Ensure ALL collaborators have pushed their work.\n'
  printf '  - Fetch/rebase locally so your branch is up-to-date.\n'
  printf '  - A backup tag will be created%s.\n' "$( [ $BACKUP = true ] && printf ' (name: %s' "$BACKUP_TAG" || printf '' )"
  printf '%s ' "Proceed? [y/N]:"; read ans || ans=""
  case "$ans" in
    y|Y|yes|YES) return 0;;
    *) err "Aborted"; return 1;;
  esac
}

run() {
  printf '[CMD] %s\n' "$*"
  if $DRY_RUN; then return 0; fi
  # shellcheck disable=SC2086
  sh -c "$*"
}

# Show plan
log "Creating empty root commit with message: '$MSG' (id: $NEWROOT)"
log "Target branch: $TARGET_BRANCH"
if $REBASE_MERGES; then log "Rebase mode: --rebase-merges"; fi
if $DRY_RUN; then warn "Dry-run enabled; no changes will be made."; fi

if ! confirm; then exit 1; fi

# Execute
run "git checkout $TARGET_BRANCH"
run "git rebase --onto $NEWROOT --root ${REBASE_MERGES:+--rebase-merges}"

# Return to previous branch if different
if [ "$CURRENT_BRANCH" != "$TARGET_BRANCH" ]; then
  run "git checkout $CURRENT_BRANCH"
fi

log "Rebase completed. The branch history now starts with the empty commit $NEWROOT."
log "If this branch is tracked remotely, you will likely need to force-push."

# Auto-push or interactive prompt to push
upstream_after=$(git rev-parse --abbrev-ref --symbolic-full-name "$TARGET_BRANCH@{upstream}" 2>/dev/null || true)
if $AUTO_PUSH; then
  if [ -n "$upstream_after" ]; then
    remote_name=${upstream_after%%/*}
    remote_branch=${upstream_after#*/}
    run "git push --force-with-lease $remote_name refs/heads/$TARGET_BRANCH:refs/heads/$remote_branch"
  else
    warn "No upstream configured for $TARGET_BRANCH; skipping auto push"
  fi
else
  if $YES; then
    warn "Skipping interactive push prompts due to --yes; run manually if desired: git push --force-with-lease"
  else
    printf '%s ' "Force-push '$TARGET_BRANCH' to its upstream now? [y/N]:"; read push_ans || push_ans=""
    case "$push_ans" in
      y|Y|yes|YES)
        if [ -n "$upstream_after" ]; then
          remote_name=${upstream_after%%/*}; remote_branch=${upstream_after#*/}
          run "git push --force-with-lease $remote_name refs/heads/$TARGET_BRANCH:refs/heads/$remote_branch"
        else
          warn "No upstream configured; skipping"
        fi
        ;;
      *) : ;;
    esac
    printf '%s ' "Force-push ALL local branches with upstreams? [y/N]:"; read push_all || push_all=""
    case "$push_all" in
      y|Y|yes|YES)
        # Iterate local branches and push to their respective upstreams
        git for-each-ref --format='%(refname:short) %(upstream:short)' refs/heads | while read -r lb ub; do
          [ -z "$ub" ] && continue
          r=${ub%%/*}; b=${ub#*/}
          run "git push --force-with-lease $r refs/heads/$lb:refs/heads/$b"
        done
        ;;
      *) : ;;
    esac
  fi
fi
