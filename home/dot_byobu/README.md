# Byobu config

This directory contains Byobu (tmux backend) user configuration managed by chezmoi.

- Config file: `~/.byobu/tmux.conf` (source: `home/dot_byobu/tmux.conf`)
- Behavior mirrors your plain tmux config (`~/.tmux.conf`) and Screen config where applicable:
  - 256-color/truecolor, history 10k, mouse enabled, vi copy-mode, visual bell/activity, auto-rename, remain-on-exit
  - Reuses your plain tmux config via: `source-file ~/.tmux.conf`

## XDG-friendly layout
Byobu does not natively follow XDG base directories. To keep configs under XDG while Byobu still works:

```sh
mkdir -p "$XDG_CONFIG_HOME/byobu"
ln -sfn "$XDG_CONFIG_HOME/byobu" "$HOME/.byobu"
```

Then place `tmux.conf` under `$XDG_CONFIG_HOME/byobu/tmux.conf` (chezmoi can manage this path too).

## Using a symlink vs `source-file`
- Symlink approach: `~/.byobu/tmux.conf -> ~/.tmux.conf`
  - Pro: single source of truth.
  - Con: you lose the ability to keep Byobu-specific overrides.
- Current approach (recommended): keep `~/.byobu/tmux.conf` and `source-file ~/.tmux.conf`, then layer Byobu-specific tweaks afterwards.

## Notes
- Byobu overlays its own status; the tmux status settings here are minimal and safe.
- If you change Byobu prefix (e.g., via byobu-config), consider updating bindings or keeping them compatible with `C-b`.
