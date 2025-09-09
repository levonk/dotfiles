# Modular Git Configuration

Managed by chezmoi. This folder replaces a monolithic `~/.gitconfig` with smaller, focused modules.

## Files

- `config`
  - Main entrypoint. Includes the modular sub-configs.
  - Adds color groups and Git LFS filter configuration.

- `sub-config/core.gitconfig`
  - Core settings and UX/safety knobs.
  - Pull: `pull.rebase = true`
  - Push: `push.autoSetupRemote = true`, `push.default = tracking`
  - Core hygiene: `autocrlf = input`, `safecrlf = true`, `attributesfile = ~/.config/git/gitattributes`,
    `excludesfile = ~/.sourcecontrol/globalignore`, `whitespace = trailing-space,space-before-tab,cr-at-eol,blank-at-eof,tab-in-indent`,
    `trustctime = false`, `editor = vim`, `ignorecase = false`
  - Safety/UX: `apply.whitespace = fix`, `help.autoCorrect = -1`, `branch.autosetupmerge = true`
  - Commit template: points to `commit-template.txt` in this directory.

- `sub-config/diff-merge.gitconfig`
  - Diff/merge behavior and tools.
  - Algorithm: `diff.algorithm = patience`, `compactionHeuristic = true`
  - Tooling: VS Code is configured for both diffs and merges.
  - Includes converters for common binary formats (image/pdf/sqlite).
  - Custom merge drivers preserved: `railschema`, `railsschema`, and `ours`.

- `sub-config/aliases.gitconfig`
  - Safe/general-purpose aliases grouped by category (commit, diff, branch, fetch/push, logs, history helpers, etc.).
  - Adds: `s`, `st`, `m`, `descendants` and more.

- `sub-config/dangerous-aliases.gitconfig`
  - Destructive or high-risk aliases (resets, wipe local changes, filter-branch, autosquash workflows, etc.).
  - Gated behind `GIT_DANGEROUS=1`. Without it, aliases refuse to run and explain why.

- `commit-template.txt`
  - Commit message template consumed by `commit.template` in core config. Uses `#` comment lines so guidance is stripped from final messages.

## Enable/Disable Dangerous Aliases

Dangerous aliases are included by default via `config` but gated at runtime.

- To enable for a shell session:

```sh
export GIT_DANGEROUS=1
```

- To keep them always disabled, you can remove the include line from `config`:

```ini
[include]
    path = sub-config/dangerous-aliases.gitconfig
```

## Notable Defaults

- Merge/Diff tool: Visual Studio Code
- Safer pushing: `push --force-with-lease` alias (`pf`)
- Helpful displays: rich log aliases (`l`, `lg`, `l50`, `l80`, etc.)
- Consistent diffs: patience algorithm, compaction heuristic, mnemonic prefixes

## Notes

- User identity (`[user]`) is intentionally not managed here.
- Kaleidoscope references have been removed in favor of VS Code tooling.
- Color setting for diff whitespace is enforced in `config` (`red reverse`).
