# Dotfiles Modularization & Modernization Migration Checklist

## 1. Modularization & Structure
- [x] Split aliases, functions, notifications into logical modules under `dot_config/shells/shared/`
- [x] Add detailed headers: purpose, shell support, chezmoi management, security, extensibility
- [x] Remove duplicate definitions from main entrypoints
- [x] Ensure all scripts are safe to source in any shell

## 2. Shell Neutrality & Extensibility
- [x] Use POSIX-compliant syntax unless shell-specific
- [x] Encapsulate shell-specific logic (preexec/DEBUG trap)
- [x] Mark TODOs for new shell support (e.g., Fish, PowerShell)

## 3. Modern Tool Aliasing & Notification
- [x] Conditionally alias legacy tools to modern equivalents if installed
- [x] Real-time notification and typo correction in interactive shells
- [x] Extensible mappings for new tools/typos

## 4. Security, Safety, and Compliance
- [x] No sensitive data or unsafe external calls
- [x] Scripts safe for all environments (local, CI, remote, non-interactive)
- [x] Security/compliance comments in headers

## 5. Documentation & Traceability
- [x] Comprehensive headers in each module
- [x] Update README for structure, usage, compliance
- [x] Document migration/testing steps here
- [x] Update .bashrc to source entrypoint.bash (not sharedrc)
- [x] Update .zshrc to source entrypoint.zsh (not sharedrc)

## 6. Testing & Validation
- [x] BDD `.feature` file for all critical behaviors
- [x] Automated bats/shellcheck tests
- [x] Manual test in Bash/Zsh (aliases, notifications, typos, safety)
- [x] Idempotency: safe to re-source

## 7. Future-Proofing & Collaboration
- [x] All scripts managed by chezmoi
- [x] Structure/headers support easy extension
- [x] Compliance, licensing, contribution guidelines referenced

## 8. Commit & Change Management
- [x] Use detailed commit messages referencing checklist items
- [x] Run all tests before committing

---

## BDD & Automated Test Artifacts
- [x] `internal-docs/requirements/gherkin/features/dotfiles-modularization.feature`
- [x] `internal-docs/requirements/test/dotfiles-modularization.bats`
- [x] `internal-docs/requirements/test/.shellcheckrc`

## Manual Test Notes
- [x] Bash: All aliases, notifications, and typo fixes work as expected (via .bashrc → entrypoint.bash → sharedrc)
- [x] Bash: Startup order comments present in .bashrc and entrypoint.bash
- [x] Bash: Login shell startup via dot_bash_profile, dot_bash_login, dot_profile tested and sources .bashrc
- [x] Zsh: All aliases, notifications, and typo fixes work as expected (via dot_zshrc → entrypoint.zsh → sharedrc)
- [ ] Unsupported shell: No errors or side effects

---

## BDD & Automated Test Artifacts
- [x] Bash/Zsh: Entrypoint wrapper and sharedrc logic covered by BDD `.feature` and `.bats` tests
- [x] `internal-docs/requirements/gherkin/features/dotfiles-modularization.feature`
- [x] `internal-docs/requirements/test/dotfiles-modularization.bats`
- [x] `internal-docs/requirements/test/.shellcheckrc`

---

## Compliance TODO
- [x] Review all script headers for compliance and licensing notes (Bash/Zsh complete)
- [x] Ensure onboarding/startup order comments are present in all shell entrypoints (.bashrc, entrypoint.bash, entrypoint.zsh)
- [x] Add `.feature` and test coverage for Bash/Zsh entrypoints and modularization (see below)
    - `internal-docs/requirements/gherkin/features/dotfiles-modularization.feature` (Bash/Zsh entrypoint, sharedrc logic)
    - `internal-docs/requirements/gherkin/features/dotfiles-zsh.feature` (Zsh-specific scenarios, if present)
    - `internal-docs/requirements/gherkin/features/dotfiles-bash.feature` (Bash-specific scenarios, if present)
    - Add new `.feature` files for any new modules or behaviors added in future
- [ ] Update LICENSE and admin/licenses.md as needed
- [x] Ensure CI covers Bash login and non-login startup, referencing .github/workflows/ci-dotfiles.yml
