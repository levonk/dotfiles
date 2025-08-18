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

- `dot_config/shells/shared/` — Modular aliases, functions, notifications
- `dot_config/shells/zsh/entrypoint.zsh` — Zsh entrypoint: sources universal sharedrc and Zsh-specific logic
- `dot_config/shells/bash/entrypoint.bash` — Bash entrypoint: sources universal sharedrc and Bash-specific logic
- `dot_config/shells/shared/modern-tool-notify.sh` — Modern tool notification and typo correction plugin (supports Bash/Zsh)

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

## Git commit hooks (pre-commit)

This repo uses [pre-commit](https://pre-commit.com/) to enforce template and shell quality on commit.

•  **Install pre-commit**

```bash
pip install pre-commit || python3 -m pip install --user pre-commit
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

- **ShellCheck**: [mirrors-shellcheck](https://github.com/pre-commit/mirrors-shellcheck)
  - Runs on non-template shell scripts in `home/.chezmoiscripts/*.sh`.
  - CI additionally runs ShellCheck on rendered templates.

Hook definitions live in `.pre-commit-config.yaml`.

## Contributing

- Follow header/comment style for all new scripts
- Document all changes in the migration checklist and README
- Run all tests before submitting changes
