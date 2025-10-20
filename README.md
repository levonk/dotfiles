# Modular, Secure, and Modern Dotfiles Structure

## Overview

This repository implements a modular, shell-neutral, and security-conscious dotfiles system, managed by chezmoi. All aliases, functions, and notifications are organized into logical modules under `dot_config/shells/shared/` for maintainability and extensibility.

## Quick Start: Setup chezmoi and apply dotfiles

### Prerequisites (git, curl)

#### Linux (Debian/Ubuntu)

```bash
sudo apt update && sudo apt install -y git curl
```

#### Fedora

```bash
sudo dnf makecache
sudo dnf install -y git curl
```

#### RHEL/CentOS/AlmaLinux/Rocky

```bash
sudo dnf makecache
sudo dnf install -y git curl
```

#### Arch

```bash
sudo pacman -Sy
sudo pacman -S --needed git curl
```

#### openSUSE (zypper)

```bash
sudo zypper refresh
sudo zypper install -y git curl
```

#### macOS (Homebrew)

```bash
brew update
brew install git curl
```

### Optional: Rust toolchain (cargo)

Install via rustup (recommended on Linux/macOS):

```bash
curl https://sh.rustup.rs -sSf | sh -s -- -y
# activate in current shell
source "$HOME/.cargo/env"
```

### Install chezmoi

Prefer your package manager, or use the official installer.

On RHEL/CentOS or openSUSE, if `chezmoi` is not available in your configured repositories, use the official installer below.

#### Package manager

```bash
# Debian/Ubuntu
sudo apt install -y chezmoi
# Fedora
sudo dnf install -y chezmoi
# Arch
sudo pacman -S chezmoi
# macOS (Homebrew)
brew install chezmoi
```

#### Official installer (Linux/macOS)

```bash
sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$XDG_BIN_HOME"
# Ensure ~/.local/bin is on your PATH
export PATH="$XDG_BIN_HOME:$PATH"
```

### Initialize and apply this repo's dotfiles to $HOME

Using SSH (if you have GitHub SSH keys configured):

```bash
chezmoi init --apply git@github.com:levonk/dotfiles.git
```

Using your repository URL (replace `<REPO_URL>` with your clone URL, e.g. <https://github.com/levonk/dotfiles.git>):

```bash
chezmoi init --apply https://github.com/levonk/dotfiles.git
```

From a local clone of this repo (run from the repo root):

```bash
chezmoi init --source=. --apply
```

> Note: This repo sets `.chezmoiroot` to `home`, so running from the repo root lets chezmoi pick up source files correctly.

Re-apply later after changes:

```bash
chezmoi apply -v
```

This will materialize files from `home/` into your `$HOME` (e.g., `~/.config/shells/...`).

### Required tools for template rendering

Some templates call external tools during rendering. Ensure these are installed before running `chezmoi apply`:

- `jq` — used to generate/merge JSON (e.g., VS Code `settings.json` templates)

Install examples:

```bash
# Debian/Ubuntu
sudo apt-get update && sudo apt-get install -y jq

# Fedora/RHEL/CentOS (dnf)
sudo dnf install -y jq

# Arch
sudo pacman -S --needed jq

# macOS (Homebrew)
brew install jq
```

## Key Features

- **Modularization:** Aliases, navigation, platform utilities, typo fixes, and notifications are split into separate files with clear headers.
- **Shell Neutrality:** All scripts use POSIX-compliant syntax and only activate shell-specific features conditionally.
- **Modern Tool Awareness:** Legacy commands are aliased to modern tools (ripgrep, bat, fd, zoxide) if installed, with real-time notifications and typo correction.
- **Security:** No scripts leak sensitive data or make unsafe external calls. All scripts are safe to source in any environment.
- **Extensibility:** Easily add new modules or extend shell support. All files are managed by chezmoi for traceability.

## Directory Layout

- `home/current/dot_config/shells/shared/` — Modular aliases, functions, notifications
- `home/current/dot_config/shells/zsh/entrypoint.zsh` — Zsh entrypoint: sources universal sharedrc and Zsh-specific logic
- `home/current/dot_config/shells/bash/entrypoint.bash` — Bash entrypoint: sources universal sharedrc and Bash-specific logic
- `home/current/dot_config/shells/shared/modern-tool-notify.sh` — Modern tool notification and typo correction plugin (supports Bash/Zsh)
- `scripts/` — Utility scripts for development and diagnostics (e.g., `repo-health.sh`, `validate-shell-template.sh`, `prompt-diagnose.zsh`)
- `scripts/danger/danger-scratch-apply.sh` — Safe, instrumented Chezmoi apply harness with preflights, dry-run gates, and logs (`/tmp/danger-scratch-apply.log`). Supports `--no-git-checks` and timeouts via env vars.
- `scripts/git-status-digest.sh` — Auditable repo state snapshot (CWD, repo root, porcelain, staged/unstaged/untracked, submodules, worktrees, in-progress ops, ahead/behind)
- `scripts/tests/` — Test assets and runners (e.g., `shell-tests.bats`, `devcontainer-test.sh`)

## Shell Startup Sequence

This repository uses an optimized, multi-stage loading sequence for shell environments, especially for Zsh. Understanding this sequence is crucial for debugging and customization.

### Zsh Login Shell Execution Order

1.  **`~/.zshenv`**
    *   **Purpose**: Sourced first on *any* Zsh invocation (login, interactive, or script).
    *   **Actions**:
        1.  Sets `export ZDOTDIR="$HOME/.config/shells/zsh"`. This tells Zsh to find its configuration files (`.zshrc`, `.zprofile`, etc.) in this directory instead of `$HOME`.
        2.  Sources `$HOME/.config/shells/shared/env/__xdg-env.sh` to establish XDG environment variables (`$XDG_CONFIG_HOME`, etc.).
        3.  Sources `$ZDOTDIR/env/history.zsh` to configure shell history settings early.

2.  **`$ZDOTDIR/.zprofile`**
    *   **Purpose**: Sourced for **login shells** after `~/.zshenv`.
    *   **Action**: Typically used for commands that should run only once at the start of a login session.

3.  **`$ZDOTDIR/.zshrc`**
    *   **Purpose**: Sourced for **interactive shells** after `.zprofile`.
    *   **Action**: Immediately sources `$ZDOTDIR/entrypoint.zsh`, delegating control to the custom framework.

4.  **`$ZDOTDIR/entrypoint.zsh`**
    *   **Purpose**: Acts as a bridge to the shared shell framework.
    *   **Action**: Sources `$XDG_CONFIG_HOME/shells/shared/entrypointrc.sh`.

5.  **`.../shared/entrypointrc.sh` (Core Logic)**
    *   **Purpose**: This is the main, performance-optimized script that orchestrates the rest of the shell environment setup.
    *   **Actions (Eagerly Sourced)**:
        1.  **Core Utilities**: Loads performance and utility scripts from `$XDG_CONFIG_HOME/shells/shared/util/` (e.g., `sourcing-registry.sh`, `lazy-loader.sh`).
        2.  **Zsh Plugins**: Sources `$ZDOTDIR/util/om-my-zsh-plugins.zsh`.
        3.  **Zsh Prompt**: Sources `$ZDOTDIR/prompts/p10k.zsh` to set up the command prompt.
        4.  **Essential Aliases**: Sources `$XDG_CONFIG_HOME/shells/shared/aliases/modern-tools.sh`.
        5.  **Zsh Environment Files**: Sources all files matching `*.{zsh,sh,bash,env}` inside `$ZDOTDIR/env/`.

6.  **Lazy-Loaded Modules**
    *   The `entrypointrc.sh` script also *registers* many other scripts to be loaded on-demand when a specific command or alias is first used. This improves startup speed. These include:
        *   **Shared Aliases**: Files in `$XDG_CONFIG_HOME/shells/shared/aliases/`.
        *   **Shared Utilities**: Files in `$XDG_CONFIG_HOME/shells/shared/util/`.
        *   **Zsh-Specific Modules**: Files in `$ZDOTDIR/aliases/`, `$ZDOTDIR/util/`, and `$ZDOTDIR/completions/`.

7.  **`$ZDOTDIR/.zlogin`**
    *   **Purpose**: Sourced last for **login shells**.
    *   **Action**: Used for any commands that need to run at the very end of the login process.



## Usage

1. **Install modern CLI tools** (bat, batcat, neovim, fd, rg, fzf, zoxide) for best experience.
2. **Source your shell entrypoint** in your shell config:
   - For Bash: source `~/.config/shells/bash/entrypoint.bash` in your `.bashrc`
   - For Zsh: source `~/.config/shells/zsh/entrypoint.zsh` in your `.zshrc`
3. **All modules are safe to source in any shell.**
4. **Extend or add new modules** by copying the header style and following the modular structure.

## Testing & Compliance

- BDD `.feature` tests and automated shell tests are in `internal-docs/requirements/`
- All scripts must:
  - Be POSIX-compliant or conditionally shell-specific
  - Have a detailed header (purpose, shell support, chezmoi management, security, extensibility)
  - Pass shellcheck and bats tests
  - Not leak sensitive data or make external calls

## Build & Test

Use the provided scripts and tests to validate the repository locally before committing changes.

### 1) Quick health check

Run consolidated, read-only checks (shellcheck, shfmt diff, JSON/YAML sanity, optional bats):

```bash
scripts/repo-health.sh        # full pass
scripts/repo-health.sh --quick  # skip slower checks like bats
```

Flags:

- `--quick` — faster pass; skips bats
- `--no-shellcheck`, `--no-shfmt`, `--no-bats`, `--no-json`, `--no-yaml` — selectively disable checks

### 1b) Chezmoi apply (danger harness)

Use the guarded apply harness to run `chezmoi` with strong preflights and dry-run gates:

```bash
scripts/danger/danger-scratch-apply.sh           # full preflights + dry-runs + apply
scripts/danger/danger-scratch-apply.sh --no-git-checks  # skip git cleanliness preflight
```

Environment variables:

- `DANGER_APPLY_TIMEOUT_SECS` — outer timeout for real apply (default 600)
- `DANGER_DRYRUN_TIMEOUT_SECS` — timeout per dry-run (default 90)
- `DANGER_SKIP_GIT_PREFLIGHT=1` — skip git cleanliness preflight
- `DANGER_SKIP_DRYRUN=1` — skip all dry-runs (not recommended)

Logs:

- Main: `/tmp/danger-scratch-apply.log`
- Strace (when available): `/tmp/danger-chezmoi-apply-real.strace.log`

### 1c) Repo status digest

Get a concise, auditable snapshot of the current repo state before committing:

```bash
scripts/git-status-digest.sh        # standard snapshot
scripts/git-status-digest.sh --all  # include stashes and last 5 commits
```

Flags and workflow alignment:

- `--fail-if-dirty` — exit non-zero if untracked, staged, or modified files exist, or if branch is ahead of upstream. Mirrors the cleanliness gate in your workflow.
- `--preflight-health` — runs `scripts/repo-health.sh --quick` from repo root (read-only checks).
- `--suggest-commits` — prints suggested grouped `git add` and `git commit` commands by scope (scripts, tests, shells, docs, home, misc).
- `--summary-new N` — prints the last N commits with stats.

Examples:

```bash
# Strict gate before committing
scripts/git-status-digest.sh --fail-if-dirty

# Health + suggestions without mutating the repo
scripts/git-status-digest.sh --preflight-health --suggest-commits

# After committing, show a quick summary of recent commits
scripts/git-status-digest.sh --summary-new 3
```

### Template Synchronization (`template-sync.bash`)

This script synchronizes files from a source directory to one or more destination directories, creating template files that include the source files. It can be run in two modes: batch mode (recommended) or single-run mode.

#### Batch Mode (Recommended)

For managing multiple synchronization tasks, use a JSONC configuration file.

**1. Create a configuration file:**

Create a file (e.g., `config/template-sync-jobs.jsonc`) with an array of job objects:

```jsonc
// config/template-sync-jobs.jsonc
[
  {
    "name": "AI Workflows Sync",
    "src": "dot_config/ai/workflows",
    "dest": [
      "dot_codeium/windsurf/global_workflows",
      "dot_codeium/windsurf-next/global_workflows"
    ],
    "dest_template_type": "go",
    "tree_handling": "flatten",
    "transform": "none",
    "delete_stale": true
  }
]
```

**2. Run the script:**

```bash
# Run all jobs in the config file
scripts/sync/template-sync.bash --config config/template-sync-jobs.jsonc

# Run a specific job by name
scripts/sync/template-sync.bash --config config/template-sync-jobs.jsonc --jobs "AI Workflows Sync"
```

#### Single-Run Mode

For a one-off task, you can use command-line arguments:

```bash
scripts/sync/template-sync.bash \
  --src "dot_config/ai/workflows" \
  --dest "dot_codeium/windsurf/global_workflows" \
  --dest "dot_codeium/windsurf-next/global_workflows" \
  --tree-handling "flatten" \
  --dest-template-type "go" \
  --delete-stale
```

### 2) Run tests

- Shell tests (if `bats` is installed):

```bash
bats -r scripts/tests
```

- Devcontainer smoke/CI helpers:

```bash
scripts/tests/devcontainer-test.sh
scripts/tests/run-devcontainer-ci.sh
```

### 3) Pre-commit hooks

Enable and run pre-commit hooks to enforce template and shell quality:

```bash
pre-commit install
pre-commit run --all-files
```

### Iterative Debugging Cycle

For debugging startup issues or `chezmoi apply` failures, follow this iterative cycle until all tests pass:

1.  **Commit Changes**: Commit any pending changes with a descriptive message. This is crucial as `chezmoi` often operates on the committed state of files.

2.  **Run Test and Apply Cycle**: Execute the following command to clear caches, run containerized tests, and perform a full `chezmoi` purge and apply cycle:

    ```bash
    rm -rf ~/.cache/dotfiles; scripts/tests/test-in-container.bash && ~/.local/bin/chezmoi purge --force && ~/.local/bin/chezmoi init . && ~/.local/bin/chezmoi apply --dry-run && ~/.local/bin/chezmoi apply --dry-run
    ```

3.  **Fix Failures**: If any step in the command fails, diagnose and fix the underlying issue.

4.  **Repeat**: Continue this cycle until the command completes successfully.

> **Note**: This process is designed to ensure that the shell startup environment (`$STARTUP_TEST_ENV`) is correctly configured and tested, as validated by tests in `scripts/tests/entrypointrc-file-listing.bats`.

### Troubleshooting `chezmoi apply` Freezes

When `chezmoi apply` freezes, it's almost always because a `.chezmoiscripts` template is hanging. These scripts are rendered by `chezmoi` into a temporary directory (like `/tmp/{randome#}.chezmoi-run-script.*sh`) and executed. A freeze typically occurs if a script waits for user input (e.g., a password prompt) in a non-interactive session.

Here’s how to diagnose the issue:

**1. Identify the Hanging Script**

While `chezmoi apply` is frozen, inspect the process tree in another terminal to find the script `chezmoi` is currently executing.

```bash
# In another terminal
ps aux | grep chezmoi
```

This will often reveal the path to the temporary script in `/tmp/` that is causing the hang.

**2. Isolate the Problem with Binary Search**

You can use Go template logic within your `.chezmoiscripts` to selectively disable them, allowing you to perform a "binary search" to find the culprit.

-   **Create a debug variable in your `chezmoi` config:**
    Add a variable to your `~/.config/chezmoi/chezmoi.toml` file to control which scripts run.

    ```toml
    [data]
      debug_scripts = { skip = ["script1-to-skip.sh", "script2-to-skip.sh"] }
    ```

-   **Wrap your scripts in a conditional template:**
    Modify your `.chezmoiscripts/run_once_*.sh.tmpl` files to check this variable.

    ```go-template
    {{- /* .chezmoiscripts/run_once_problematic-script.sh.tmpl */ -}}
    {{- if not (has "problematic-script.sh" .debug_scripts.skip) -}}
    #!/bin/bash
    set -euo pipefail

    # ... original script content ...
    echo "Running the problematic script"
    # This command might hang
    read -p "Enter something: "
    {{- end -}}
    ```

-   **Iterate:**
    By adding script names to the `skip` array in your `chezmoi.toml`, you can systematically disable scripts until `chezmoi apply` no longer freezes. This will isolate the problematic script. Once found, you can fix it (e.g., remove the interactive prompt) or permanently disable it for non-interactive environments.

**3. Run with Verbose and Debug Flags**

Running `chezmoi` with increased verbosity can provide more context.

```bash
chezmoi apply -v --debug
```

This will show which scripts are being executed right before the freeze occurs, helping you narrow down the search.

## Git commit hooks (pre-commit)

This repo uses [pre-commit](https://pre-commit.com/) to enforce template and shell quality on commit.

•  **Install pre-commit**

```bash
pip install pre-commit || pip install --user pre-commit
uv pip install pre-commit || uv pip install --user pre-commit
```

•  **Enable hooks in this repo**

```bash
pre-commit install
```

•  **Run hooks against all files** (first-time baseline)

```bash
pre-commit run --all-files
```

### Hooks configured

- **Template policy validator (local)**: `scripts/validate-shell-template.sh`
  - For `*.sh`, `*.sh.tmpl`: requires `set -euo pipefail` in first 20 lines, forbids `{{-` on line 2, and forbids `-}}` on the last non-empty line.
  - For `*.ps1.tmpl`: first non-empty line must be a Go template `if` guard; `#Requires` must be inside the guard.

- **ShellCheck (system)**
  - Runs on non-template shell scripts in `home/.chezmoiscripts/*.sh` using your locally installed `shellcheck`.
  - Install `shellcheck` via your package manager (e.g., Debian/Ubuntu: `sudo apt-get install -y shellcheck`, macOS: `brew install shellcheck`).
  - CI additionally runs ShellCheck on rendered templates.

Hook definitions live in `.pre-commit-config.yaml`.

## Contributing

- Follow header/comment style for all new scripts
- Document all changes in the migration checklist and README
- Run all tests before submitting changes
