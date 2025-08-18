# CI policy for ChezMoi script templates

This repository enforces guardrails to prevent common template/shebang pitfalls that can break rendered scripts during `chezmoi apply`.

## Policy

- Shebang integrity (shell templates)
  - First line must be `#!/usr/bin/env bash` (or `#!/bin/bash`).
  - The line after the shebang must not start with a Go template trim marker (`{{-`).
  - Preserve trailing newline at EOF; do not use `-}}` on the last line.
- Early trim markers
  - Avoid `{{-` within the first 5 lines of any `.sh.tmpl`. This prevents token concatenation near the shebang and early syntax.
- PowerShell templates
  - `.ps1.tmpl` must begin with an OS guard on the first non-empty line, e.g. `{{ if eq .chezmoi.os "windows" }}`.
  - Place `#Requires -Version ...` inside the OS guard so nothing renders on non‑Windows.

## Rationale

- `{{-` left-trims the preceding newline/whitespace. If used on line 2, it can glue the shebang to the next token, causing errors like:
  `/usr/bin/env: 'bash# ...': No such file or directory`.
- `-}}` right-trims; when used on the last line, it removes the final newline which many tools expect.
- Guarding `.ps1.tmpl` prevents ChezMoi from rendering/executing PowerShell on Unix.

## CI checks

Implemented in `.github/workflows/ci-dotfiles.yml` under the step "Validate shebangs and template guards":

- Validate `.sh.tmpl` shebang line, no `{{-` on line 2, and warn on missing EOF newline.
- Fail if the last non-empty line of `.sh.tmpl` ends with `-}}` (newline stripped).
- Fail if `{{-` appears within the first 5 lines of `.sh.tmpl` (except line 1).
- Ensure `.ps1.tmpl` starts with an OS `if` guard on the first non-empty line.

## Examples

Good:

```bash
#!/usr/bin/env bash
{{ if ne .chezmoi.os "windows" }}
# body
{{ end }}
```

Avoid:

```bash
#!/usr/bin/env bash
{{- if ne .chezmoi.os "windows" -}}  # trims and may glue to shebang
# body
{{ end -}}  # strips trailing newline at EOF
```

PowerShell:

```powershell
{{ if eq .chezmoi.os "windows" }}
#Requires -Version 5.1
# body
{{ end }}
```
