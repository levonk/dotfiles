# Emacs configuration

Location: `home/dot_config/emacs/`

## Overview

This is a pragmatic, legacy-friendly Emacs setup focused on C/C++/Perl editing, cscope navigation, Org basics, and several custom modes under `site-lisp/`.

Highlights:
- Robust `load-path` for `site-lisp/` relative to this directory.
- Safe GUI-only color tweaks to avoid TTY issues.
- Hide/Show convenience bindings for code folding.
- Defensive cscope integration that won’t error if `xcscope` isn’t available.
- Cleaner auto-mode patterns using `\'` anchors.
- Early startup optimizations via `early-init.el` (Emacs 27+).

## File structure

- `init.el` — Main configuration.
- `early-init.el` — Startup optimizations; runs before `init.el` on Emacs 27+.
- `site-lisp/` — Local modes and utilities:
  - `graphviz-dot-mode.el`
  - `yicf-mode.el`
  - `lsl*.el` family
  - `xcscope.el` (empty placeholder; see cscope notes)

## Requirements

- Emacs 27+ recommended (works on older releases but `early-init.el` is ignored).
- Optional: cscope (`xcscope` Emacs package). If not present or broken, the config degrades gracefully.

## Notable behaviors

- Background/foreground/cursor color is set only when `display-graphic-p` is true.
- Tabs are disabled globally (`indent-tabs-mode` = nil; `tab-width` = 4).
- Folding helpers:
  - `C-+` toggles hiding at point.
  - `C-\\` toggles selective display.
  - In C-family, `hs-minor-mode` is enabled by default with local keybindings.
- Org-mode:
  - Files ending in `.org` and `/todo.txt` open in `org-mode`.
  - `C-c l` stores link; `C-c a` opens agenda.

## cscope notes

- The configuration attempts `(require 'xcscope)` inside `ignore-errors`.
- If `xcscope` isn’t available or doesn’t `(provide 'xcscope)` (e.g., an empty file), all cscope-specific functions and keybindings are skipped.
- When available:
  - `find-tag` is remapped to `cscope-find-this-symbol`.
  - In cscope buffers: `q` buries buffer, `C-RET` opens entry in the same window.

## Custom commands

- `my-cleanup-buffer` — Reindent region and clean trailing whitespace.
- `untabify-buffer` / `untabify-and-save-buffer` — Untabify via byte positions.
- `indent-whole-buffer-command` — Reindent whole buffer (legacy helper).
- `web-open` — Minimal URL downloader into a buffer (uses `wget`).

## Tips

- For modern `cl` usage, consider migrating `loop` to `cl-loop` and requiring `cl-lib`. The current config keeps legacy `cl` for compatibility.
- If you want to change colors globally, prefer themes instead of `set-*-color` calls.

## Troubleshooting

- If Emacs errors on startup around cscope, ensure `site-lisp/xcscope.el` isn’t an empty placeholder or install a proper `xcscope` package that provides the feature.
- If custom modes do not load, verify `site-lisp/` is on `load-path`. The current config auto-adds it relative to `init.el`.
