---
modeline: "vim: set ft=markdown:"
---

# ChezMoi Templating: Project Rules and Patterns

This rule captures how templates must be authored in this repo to avoid apply-time crashes and keep includes composable.

## Core Principles

- **Callers own variables.** Files that include partials (e.g., analysis templates) are responsible for computing and passing values. Wrappers should remain pass-through.
- **Partials must be tolerant.** Real partials under `.chezmoitemplates` must not crash when included with a thin context. Use `hasKey`-guarded locals with sensible defaults.
- **Never render include-only wrappers as files.** If a template exists purely to `includeTemplate`, place the real implementation in `.chezmoitemplates` and ensure paths in callers reference that version.
- **Absolute include paths.** Use full repo-relative include paths to the `.chezmoitemplates` version to keep resolution consistent:
  - `config/ai/workflows/.../partials/...`

## Required Patterns

### 1) Guarded locals in partials

Use `hasKey` to avoid missing-key errors; then reference locals everywhere.

```gotemplate
{{- $PeriodName := "Journal Analysis" -}}
{{- if hasKey . "PeriodName" -}}
  {{- $PeriodName = .PeriodName -}}
{{- end -}}
```

Apply the same pattern for `$PeriodLabel`, `$RangeLabel`, `$Inputs`, and any other inputs. Prefer empty string or empty list defaults.

### 2) Callers compute context once

Before `includeTemplate`, compute what you need; avoid inline expressions that can be eagerly evaluated.

```gotemplate
{{- $inputs := (list) -}}
{{- if hasKey . "entries" -}} {{- $inputs = .entries -}} {{- end -}}
{{- $label := "" -}}
{{- if hasKey . "month_label" -}} {{- $label = .month_label -}} {{- end -}}

{{ includeTemplate "config/ai/workflows/.../journal-analysis-core.md" (dict
  "PeriodLabel" "Month"
  "PeriodName" "Monthly Journal Analysis"
  "RangeLabel" $label
  "Inputs" $inputs
) }}
```

### 3) Meta partial defaults

Meta/frontmatter partials must not explode if overrides are absent. Compute defaults via locals:

```gotemplate
{{- $runtimeMin := "5m" -}}
{{- if hasKey . "runtimeMin" -}} {{- $runtimeMin = .runtimeMin -}} {{- end -}}
```

### 4) Path helpers

Helpers that require keys (e.g., `Helper`, labels) should be called by the caller with explicit dicts. The helper partial can optionally guard for absence and no-op.

## Do/Don’t

- Do: keep wrappers as 1‑line includes; do not move or render them as output files.
- Do: implement robustness inside `.chezmoitemplates` partials.
- Don’t: depend on `.| default` alone; use `hasKey` to avoid missing-key panics when key is truly absent.
- Don’t: mix data computation with include paths; compute then pass.

## Common Errors and Fixes

- `map has no entry for key "X"` inside a partial:
  - Fix: add `hasKey`-guarded locals in the partial, or compute `$X` in caller before include and pass via dict.
- Wrong include path (templates vs workflows):
  - Fix: use `config/ai/workflows/...` path for all journal includes.

## Journal-Specific Conventions

- All analysis templates compute `$inputs` and `$label` via `hasKey` before including core.
- Core (`journal-analysis-core.md`) uses `$PeriodName`, `$PeriodLabel`, `$RangeLabel`, `$Inputs` locals.
- Meta (`journal-meta.md.tmpl`) uses guarded runtime/tag locals.

## Minimal Checklist

- [ ] Partial defines `hasKey`-guarded locals for every external key it reads.
- [ ] Caller computes and passes required values with `dict`.
- [ ] All includes use `.chezmoitemplates` workflow paths.
- [ ] No wrapper file performs variable expansion.
- [ ] ChezMoi apply passes with no missing-key errors.
