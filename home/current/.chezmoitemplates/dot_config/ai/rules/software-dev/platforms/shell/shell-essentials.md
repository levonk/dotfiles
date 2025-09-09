---
description: Shell Scripting Essentials (Safe Ops, Tests, Tooling)
use_when:
  - "*.sh"
  - "*/bin/*"
  - "*/scripts/*"
  - "*.zsh"
  - "*.bash"
---

# Shell Scripting Essentials

Critical rules to write, change, and run shell scripts safely. Derived from lessons in `scripts/danger/danger-scratch-apply.sh`.

Use when: editing or creating shell scripts, CI jobs, or local helpers.

## Project Integration & Structure

- Respect repository structure. Shared, shell-agnostic logic belongs in `home/current/dot_config/shells/shared/{util,prompt,env}`. Keep per-shell hooks/activation in `.../zsh/{util,prompt,env}` or `.../bash/{util,prompt,env}`.
- Do not refactor across shells unless explicitly asked. Keep compatibility.
- Do not change dependencies/configs unless explicitly tasked.

## Authoring Standards

- Use bash with strict mode at the top of executable scripts:
  ```sh
  #!/usr/bin/env bash
  set -euo pipefail
  ```
- Provide small helpers like `command_exists() { command -v "$1" >/dev/null 2>&1; }`.
- Guard PATH additions; avoid duplicates:
  ```sh
  case ":$PATH:" in *":$HOME/.local/bin:"*) : ;; *) export PATH="$HOME/.local/bin:$PATH" ;; esac
  ```
- Prefer portability; avoid non-POSIX features unless bash-only is declared.
- Log clearly to stderr or a log file for long-running flows.

## Required Preflights (Fail Fast)

Before any destructive or stateful action, confirm tools and environment:

- Validate required tools; exit with a clear message if missing:
  - Required: `git`, `chezmoi`, `timeout`.
  - Optional (log presence): `strace`, `lsof`, `fuser`.
- Print versions for traceability:
  - `git --version`, `chezmoi --version`, `timeout --version`.
- Detect and report running processes and lock holders when relevant (example: chezmoi persistent-state DB):
  - Use `pgrep`, `lsof -F`, and `fuser -v` when available.
- Provide an interactive pause only when a TTY exists.

## Git Cleanliness Gate (Do Not Proceed if Dirty)

- Refuse to proceed when any of the following are present:
  - Untracked files: `git ls-files --others --exclude-standard`.
  - Staged changes: `git diff --cached --name-status`.
  - Unstaged modifications: `git diff --name-status`.
  - Unpushed commits: check upstream vs HEAD with `git rev-list --left-right --count @{u}...HEAD`.
- Allow an explicit override only if configured (e.g., `DANGER_SKIP_GIT_PREFLIGHT=1` or a `--no-git-checks` flag). Always log the override.

## Dry-Run First, Always

- For each destructive step, run a dry-run and only proceed on success.
- If a dry-run fails:
  1) Log a concise failure line.
  2) Re-run the same dry-run with full output tee’d to the log.
  3) Abort the pipeline with a distinct exit code.
- If `--dry-run` is unsupported by the tool, fall back to safe diagnostics (e.g., `doctor`, `status`) without failing.
- Example sequence (pseudocode):
  ```sh
  if ! dryrun_step; then exit 10; fi
  real_step
  ```

## Safety Guards for State/Workspace

- Refuse destructive operations when the target/source resolves to the current repo working tree (e.g., `chezmoi purge` when `chezmoi source-path` equals CWD).
- Decouple destructive commands from the repo CWD when possible (e.g., run purge from `$HOME`).

## Logging, Timeouts, and Diagnostics

- Use bounded timeouts for dry-runs and real apply (`timeout 90s` or configurable via env).
- Optionally enable `strace` for real apply; write traces to a file and include timestamps.
- For long operations, arm an automatic `SIGQUIT` just before the timeout to capture goroutine stacks (for Go-based tools).
- After success/failure, run a status command and log what remains to be applied.

## CLI Flags for Safety & Speed

- Support explicit flags to skip gates (with warnings):
  - `--no-git-checks` → sets `DANGER_SKIP_GIT_PREFLIGHT=1`.
  - `--no-dry-run` (optional) → sets `DANGER_SKIP_DRYRUN=1`.
- Communicate clearly in logs when these flags are used.

## Testing & Validation (Do Not Claim Done if Failing)

- Run `shellcheck` on all relevant scripts. Treat warnings and errors as issues to resolve or explicitly explain/reason about exceptions.
  ```sh
  FILES=$(git ls-files | grep -E '(\.sh$|/bin/|/util/|/env/|/aliases/)')
  [ -n "$FILES" ] && shellcheck -x $FILES || true
  ```
- Run `shfmt -d` to enforce formatting where applicable.
- Run `bats -r scripts/tests` and ensure tests pass in the project’s harness. If tests fail or scripts error, do not claim completion; fix or report clearly.
- Prefer adding a minimal stub or guard when tests expect optional utilities.

## Commit Hygiene

- Group changes by user-facing functionality; use imperative, concise titles.
- If signing is configured, sign commits; otherwise don’t force it.
- After committing, verify clean status and provide a short `git log --stat` summary.

## Example Snippets

- `command_exists` helper:
  ```sh
  command_exists() { command -v "$1" >/dev/null 2>&1; }
  ```
- PATH guard:
  ```sh
  case ":$PATH:" in *":$HOME/.local/bin:"*) : ;; *) export PATH="$HOME/.local/bin:$PATH" ;; esac
  ```
- Dry-run gate pattern:
  ```sh
  if ! tool --dry-run; then
    echo "dry-run failed; rerunning with full output" >&2
    tool --dry-run || true
    exit 12
  fi
  tool
  ```
