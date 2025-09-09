---
description: Root-cause shell init hangs or slowdowns with linting, tracing, and timeouts
auto_execution_mode: 3
---

- __Slash command__
  - Trigger from chat: `/root-cause issue_summary="<short description>"`

- __Inputs__
  - issue_summary: Short description of the problem to investigate

1) Lint locally (shell and tests)
   ```bash
   shellcheck -x $(git ls-files | grep -E '(\\.sh$|/bin/|/util/|/env/|/aliases/)')
   shfmt -d $(git ls-files | grep -E '(\\.sh$|/bin/|/util/|/env/|/aliases/)')
   bats -r scripts/tests
   ```

2) Build devcontainer image
   ```bash
   docker-compose -f .devcontainer/docker-compose.yml build dotfiles-test
   ```

// turbo
3) Quick init trace (sanity)
   ```bash
   timeout 90s docker-compose -f .devcontainer/docker-compose.yml run --rm \
     -e SHELL_INIT_TRACE=1 \
     dotfiles-test bash -lc '.devcontainer/setup.sh && zsh -lc "echo ZSH_INIT_DONE"'
   ```

// turbo
4) Timeboxed init (avoid hangs)
   ```bash
   timeout 120s docker-compose -f .devcontainer/docker-compose.yml run --rm \
     -e SHELL_INIT_TRACE=1 -e SHELL_INIT_TIMEOUT_SECS=3 \
     dotfiles-test bash -lc '.devcontainer/setup.sh && zsh -lc "echo ZSH_INIT_DONE"'
   ```

// turbo
5) CI tests with per-test timeouts
   ```bash
   timeout 300s docker-compose -f .devcontainer/docker-compose.yml run --rm \
     -e SHELL_INIT_TRACE=1 -e DEV_TEST_TIMEOUT_SECS=90 \
     dotfiles-ci
   ```

6) Narrow down if needed
   - Rerun with skips to isolate culprit:
     ```bash
     timeout 120s docker-compose -f .devcontainer/docker-compose.yml run --rm \
       -e SHELL_INIT_TRACE=1 \
       -e SHELL_INIT_SKIP="ec2-env.sh docker-env.sh pyenv.sh" \
       dotfiles-test bash -lc '.devcontainer/setup.sh && zsh -lc "echo ZSH_INIT_DONE"'
     ```
   - Remove items from the skip list one by one to find the exact file.

7) Report
   - Summarize findings, the culprit file, and the applied fix (timeouts, lazy-load, guards). Re-run steps 3–5 without skips to validate.
