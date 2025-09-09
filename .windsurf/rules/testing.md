---
trigger: always_on
---

## Root-Cause First Policy

Band-aids / work-arounds are unacceptable. Treat every failure as a symptom and identify the underlying cause before applying any workaround.

- **Diagnose deeply**: reproduce reliably, collect minimal failing cases, and trace the exact failing code path or configuration.
- **Fix at the source**: prefer durable, maintainable fixes at the origin (script, config, dependency, or environment contract).
- **Workarounds are last resort**: only use a temporary guard or skip when:
  - The upstream/root fix is infeasible immediately, and
  - The workaround is safe, minimal, documented, and tracked for removal.
- **Document clearly**: when a workaround is used, include rationale, scope, contingency to remove it in the following places:
  - an issue link `internal-docs/issues/....md` in github issue format.
  - a checklist item in `internal-docs/todo/workarounds.md`
  - `## TODO: ...` in-code comment summarizing the workaround and contingency to remove it


# Testing and Root-Cause Guide

Goal: Quickly find and fix issues surfaced by any tooling or app (not just lint or hangs). Start with fast local checks; then reproduce in a clean container; iterate from the first failing step without starting from scratch.

- __Prereqs__
  - Tools: shellcheck, shfmt, bats, jq, ripgrep, docker, docker-compose
  - Env toggles (for shell init): `SHELL_INIT_TRACE=1`, `SHELL_INIT_SKIP`, `SHELL_INIT_TIMEOUT_SECS`

- __1) Local quick checks (cheap and broad)__
  - Shell lint and formatting:
    ```bash
    FILES=$(git ls-files | grep -E '(\.sh$|/bin/|/util/|/env/|/aliases/)')
    [ -n "$FILES" ] && shellcheck -x $FILES || true
    [ -n "$FILES" ] && shfmt -d $FILES || true
    ```
  - Bats tests:
    ```bash
    bats -r tests
    ```
  - JSON/YAML sanity (avoid noisy output):
    ```bash
    git ls-files "*.json" | xargs -r -n1 jq -e . >/dev/null
    git ls-files "*.yml" "*.yaml" | xargs -r -n1 python - <<PY2
import sys, yaml
for p in sys.argv[1:]:
    yaml.safe_load(open(p))
PY2
    ```
  - Grep for common errors or TODOs:
    ```bash
    rg -nEI 'FIXME|TODO|(set -euo pipefail).*#?\s*shellcheck|command not found|No such file or directory' || true
    ```

- __2) App/script-specific checks__
  - `.local/bin/` scripts:
    - List and smoke test:
      ```bash
      ls -la ~/.local/bin || true
      for s in ~/.local/bin/*; do [ -x "$s" ] || continue; "$s" -h >/dev/null 2>&1 || echo "warn: $s help failed"; done
      ```
    - If one fails, run with tracing:
      ```bash
      bash -x path/to/script.sh 2>&1 | sed -n '1,200p'
      ```
  - Vim/Neovim errors on start:
    - Minimal start (to isolate config):
      ```bash
      vim -Nu NONE -n +'echo "minimal ok" | q'
      nvim -u NONE -n +'q'
      ```
    - Start with user config; capture errors:
      ```bash
      vim -n +'messages' +'q' 2>&1 | sed -n '1,200p'
      nvim --headless +'lua print("init ok")' +'qall' 2>&1 | sed -n '1,200p'
      ```
    - Check plugin manager health (examples):
      ```bash
      nvim --headless +'checkhealth' +'qall' | sed -n '1,400p'
      ```
  - Git hooks and ctags:
    - Verify `auto-ctags.sh` behavior only runs in projects, not $HOME.
    - In a repo, test:
      ```bash
      (cd /path/to/repo && ~/.config/shells/shared/util/auto-ctags.sh || true)
      ```

- __3) Reproduce in devcontainer (clean env)__
  - Build:
    ```bash
    #docker-compose -f .devcontainer/docker-compose.yml build dotfiles-test
    tests/devcontainer-test.sh
    ```
  - Quick shell init trace:
    ```bash
    timeout 90s docker-compose -f .devcontainer/docker-compose.yml run --rm       -e SHELL_INIT_TRACE=1       dotfiles-test bash -lc '.devcontainer/setup.sh && zsh -lc "echo ZSH_INIT_DONE"'
    ```
  - Timeboxed init (avoid hangs):
    ```bash
    timeout 120s docker-compose -f .devcontainer/docker-compose.yml run --rm       -e SHELL_INIT_TRACE=1 -e SHELL_INIT_TIMEOUT_SECS=3       dotfiles-test bash -lc '.devcontainer/setup.sh && zsh -lc "echo ZSH_INIT_DONE"'
    ```
  - CI tests with per-test timeouts (full log printed; persisted to tmp/logs/ when writable):
    ```bash
    timeout 300s docker-compose -f .devcontainer/docker-compose.yml run --rm       -e SHELL_INIT_TRACE=1 -e DEV_TEST_TIMEOUT_SECS=90       dotfiles-ci
    ```

- __4) Iterate from the first failing step__
  - If a test/lint fails, re-run only that failing test/check until it passes.
  - If shell init stalls, use trace lines to find the last sourced file:
    - Narrow with `SHELL_INIT_SKIP` and keep `SHELL_INIT_TIMEOUT_SECS=3`.
    - Patch the culprit for non-blocking behavior: short network timeouts, guard on command availability, lazy-load.
  - For app-specific issues (e.g., Vim), reduce to minimum config; then re-enable pieces until the error reappears.

- __5) Common suspects and fixes__
  - `shared/util/ssh-agent.sh`: avoid passphrase prompts at login; opt-in via `SSH_AGENT_AUTOADD_PROMPT=1`.
  - `shared/env/ec2-env.sh`: avoid network calls without short timeouts.
  - `shared/env/docker-env.sh`: do nothing if Docker socket/CLI missing; short timeouts.
  - `shared/env/pyenv.sh`: lazy initialization; avoid costly probes.
  - Prompt/git integrations: ensure large repos or `$HOME` aren’t scanned on prompt render.

- __6) Cleanup__
  - Unset `SHELL_INIT_TRACE`, `SHELL_INIT_SKIP`, `SHELL_INIT_TIMEOUT_SECS` when done.
