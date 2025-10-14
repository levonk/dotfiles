---
description: Synchronize template includes for WinSurf workflows and other docs
---

# Overview
`scripts/sync/template-sync.bash` builds Go-template include stubs so WinSurf workflows and other Markdown assets can stay in sync with source templates.

# Usage
- **Dry run**
```
./scripts/sync/template-sync.bash --dry-run
```
- **Run specific jobs** pass a JSONC config with `--config` and optionally `--jobs name1,name2`.

## Single-run mode
```
SRC_BASE='.' DEST_BASE='.' \
  ./scripts/sync/template-sync.bash \
    --src dot_config/ai/workflows \
    --dest dot_codeium/windsurf/global_workflows \
    --tree-handling flatten
```

## Config-driven mode
```
./scripts/sync/template-sync.bash \
  --config scripts/sync/template-sync.config.jsonc \
  --jobs dot_codeium_windsurf_workflows
```

# Base overrides
- **SRC_BASE** default is `home/current/.chezmoitemplates`. Set it to change the root used for `src` paths.
- **DEST_BASE** default is `home/current`. Set it when syncing into another destination tree.
- **CHEZMOI_TEMPLATES_ROOT** and **CHEZMOI_ROOT** serve as fallbacks for the two base variables for backward compatibility.

# Per-job overrides
Each entry in `scripts/sync/template-sync.config.jsonc` accepts optional `src_base` and `dest_base` fields. Leave them `null` to use `SRC_BASE` and `DEST_BASE`, or set them explicitly per job when individual directories differ.

# Verification
- **Preview results** run with `--dry-run` to list planned writes.
- **Inspect outputs** check `dot_codeium/windsurf/global_workflows/` for the generated `*.md.tmpl` files before committing.
