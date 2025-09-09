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
sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$HOME/.local/bin"
# Ensure ~/.local/bin is on your PATH
export PATH="$HOME/.local/bin:$PATH"
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
