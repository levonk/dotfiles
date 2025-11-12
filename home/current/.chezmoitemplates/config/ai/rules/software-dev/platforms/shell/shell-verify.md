---
description: Shell Script Verification Workflow (Checks & Checklist)
use_when:
  - "*.sh"
  - "*.zsh"
  - "*.bash"
  - "*/bin/*"
  - "*/scripts/*"
---

# Shell Script Verification Workflow

A practical checklist and command set to verify shell changes before saying "done." Use this anytime shell scripts are added or modified.

## Quick Checklist

- [ ] Required tools present: `git`, `shellcheck`, `shfmt`, `bats` (if tests exist).
- [ ] Repository is clean: no untracked, staged, or unstaged files left behind.
- [ ] Lint clean: `shellcheck` runs without errors; warnings reviewed or annotated.
- [ ] Format clean: `shfmt -d` shows no diffs.
- [ ] Unit tests pass with `bats -r tests`.
- [ ] If scripts orchestrate external tools, include safe dry-runs and clear logs.
- [ ] Commit(s) grouped by functionality; clean status after commit.

## Commands

Run from the repository root.

### 1) Status sanity

```sh
# Porcelain status (all files, including untracked)
git status --untracked-files=all --porcelain
```

### 2) Lint with shellcheck

```sh
# Collect typical shell script locations; ignore if no files found
FILES=$(git ls-files | grep -E '(\\.sh$|/bin/|/util/|/env/|/aliases/|/scripts/)')
[ -n "$FILES" ] && shellcheck -x $FILES || echo "[info] no shell files to lint"
```

Notes:
- Use `# shellcheck disable=SCxxxx` sparingly, with rationale.
- Prefer fixing warnings unless false positives or intentional patterns.

### 3) Format with shfmt (diff mode)

```sh
[ -n "$FILES" ] && shfmt -d $FILES || echo "[info] no shell files to format"
```

To autoformat in-place (optional):
```sh
[ -n "$FILES" ] && shfmt -w $FILES
```

### 4) Run bats tests

```sh
# Only if tests directory exists
[ -d tests ] && bats -r tests || echo "[info] bats not available or tests missing"
```

If tests fail:
- Do not claim completion.
- Fix the failure or add a minimal guard/stub under the test harness path as appropriate.

### 5) Optional environment checks (if applicable)

```sh
# chezmoi health (if this repo integrates with chezmoi)
~/.local/bin/chezmoi doctor || true
~/.local/bin/chezmoi apply --dry-run --verbose || true
```

### 6) Git cleanliness gate

```sh
# Untracked
U=$(git ls-files --others --exclude-standard)
# Staged
S=$(git diff --cached --name-status)
# Modified
M=$(git diff --name-status)

if [ -n "$U$S$M" ]; then
  echo "[error] repo not clean: untracked/staged/modified present" >&2
  git status -s -uall
  exit 2
fi
```

### 7) Commit and summarize

```sh
# Example commit (edit title/body)
git commit -m "fix-shell: harden preflights and dry-run gates" \
  -m "Add validation for required tools; gate destructive steps behind dry-runs; update logs."

git status --untracked-files=all --porcelain

git log -n 3 --oneline --decorate --stat
```

## Guidance & Best Practices

- Use `#!/usr/bin/env bash` and `set -euo pipefail` for executable scripts.
- Guard `PATH` additions; avoid duplicates.
- Provide `command_exists()` helper and feature-detect optional tools (`strace`, `lsof`, `fuser`).
- Dry-run before destructive steps; on failure, re-run and tee full output; then abort with a distinct exit code.
- For long-running operations, prefer bounded `timeout` and capture diagnostics (e.g., SIGQUIT for Go tools, `strace` when available).
- Keep logs clear and store them under a predictable path (e.g., `/tmp/your-script.log`).
- Respect repository conventions and avoid unsolicited refactors across shells.
