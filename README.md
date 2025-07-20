# Modular, Secure, and Modern Dotfiles Structure

## Overview
This repository implements a modular, shell-neutral, and security-conscious dotfiles system, managed by chezmoi. All aliases, functions, and notifications are organized into logical modules under `dot_config/shells/shared/` for maintainability and extensibility.

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
1. **Install modern CLI tools** (bat, fd, rg, zoxide) for best experience.
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

## Contributing
- Follow header/comment style for all new scripts
- Document all changes in the migration checklist and README
- Run all tests before submitting changes

## License & Compliance
- See LICENSE and compliance notes in each script header
