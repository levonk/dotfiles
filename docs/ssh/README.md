# SSH configuration behavior

This repository manages `~/.ssh/config` using three cooperating components. They are designed to be idempotent and safe across fresh and existing machines.

- __Simple modify-template__ — `home/dot_ssh/modify_dot_ssh_config.tmpl`
  - Type: chezmoi modify-template.
  - Behavior when `~/.ssh/config` exists: appends a small, standardized block (a `Host github.com` and a minimal `Host *`) only if the exact block is not already present.
  - Behavior when `~/.ssh/config` is missing: now creates the file by outputting the minimal defaults block.
  - Notes: substring-based idempotency. If the same settings exist but with different formatting, this template may append a second copy of the block.

- __Rich compose template__ — `home/.chezmoitemplates/modify_dot_ssh/config.tmpl`
  - Reads the existing SSH config if present and composes a richer configuration:
    - Public VCS section and `Match host` directives for common providers (GitHub/GitLab/etc.) with dynamic key generation via `~/.local/bin/generate-ssh-key.bash`.
    - A comprehensive Defaults section (crypto, security, and connection settings) and an `Host *`/`Protocol 2` fallback if missing.
  - Uses the resolved Git user (see `docs/SSH_KEY_CONFIGURATION.md`) for naming keys.
  - Adds provider `Match` rules only when no `IdentityFile` is already configured for that host, avoiding any override of existing keys.

- __Run-once patch script__ — `home/.chezmoiscripts/run_once_after_patch-ssh-config.sh.tmpl`
  - Ensures `~/.ssh/config` exists, then reconciles the first `Host *` block by appending missing desired defaults only. Existing values are preserved and not rewritten.
  - If no `Host *` block exists, appends a new one containing all desired lines (including modern crypto defaults).

## Execution model and interplay

- The simple modify-template guarantees a minimal baseline exists (and now creates the file if missing).
- The run-once patch script performs an intelligent merge of defaults inside the first `Host *` block, avoiding duplication and preserving user-specific lines.
- The rich compose template adds provider-specific `Match` rules and a comprehensive Defaults section when absent.

Because the simple modify-template uses exact substring matching, if formatting differs it may still append its block. The run-once patch script then normalizes the first `Host *` block by adding any missing directives without clobbering existing ones.

## How Git user is determined (for key naming)

See `docs/SSH_KEY_CONFIGURATION.md` for the resolution order of the git user (environment/chezmoi/user fallback) and the key-generation flow.

## Permissions and modes

- SSH directory: `~/.ssh` is enforced to mode `700`.
- SSH config file: `~/.ssh/config` is enforced to mode `600`.
- Enforcement via two mechanisms:
  - `.chezmoiattributes` contains `/.ssh/config mode=0600`.
  - The run-once patch script sets `chmod 700 ~/.ssh` and `chmod 600 ~/.ssh/config` after writing.

## Preview and apply changes safely

- Preview differences: `chezmoi diff --destination ~/.ssh/config`
- Apply changes: `chezmoi apply --destination ~/.ssh/config`

## References

- Chezmoi modify templates: https://www.chezmoi.io/user-guide/modify-templates/
- Chezmoi templates: https://www.chezmoi.io/user-guide/templates/
- Chezmoi scripts: https://www.chezmoi.io/user-guide/scripts/
- OpenSSH client configuration (ssh_config): https://man.openbsd.org/ssh_config
