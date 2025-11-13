---
description: Robust Go/chezmoi template rules; prevent missing-key crashes; consistent defaults; safe includes
---

# Go Template Rules for Chezmoi (Safe, Predictable, Portable)

These rules ensure templates render reliably across machines and states (fresh installs, after `chezmoi purge`, CI). They prioritize correctness over brevity.

## Core Principles

- **Never access possibly-missing keys with `.key`**; it errors for map-based dots. Use guards.
- **Defaults must be applied after a safe lookup**, not as a rescue for a failed lookup.
- **Be explicit with types**; quote strings, don’t quote booleans or numbers.
- **Fail closed for structure**: verify parent objects exist before indexing children.
- **Prefer standard library + chezmoi-provided funcs**; avoid assumptions about Sprig breadth.

## Safe Key Access (Maps)

⭐ Best:

```gotemplate
{{ "{{" }} (or (and (hasKey . "summarize_level") (index . "summarize_level")) "standard") {{ "}}" }}
```

⚠️ Bad:

```gotemplate
{{- "{{" }} .summarize_level | default "standard" {{ "}}" -}}  # .summarize_level errors if key missing
```

Why: In Go templates, `.key` on a map fails before pipes run; `default` won’t catch it.

## Nested Structures

Use `hasKey` at each level before `index`.

```gotemplate
{{ "{{" }} if and (hasKey . "render") (hasKey (index . "render") "language") {{ "}}" }}
  {{ "{{" }} index (index . "render") "language" {{ "}}" }}
{{ "{{" }} else {{ "}}" }}
  en
{{ "{{" }} end {{ "}}" }}
```

For multiple fields, assign locals to reduce noise:

```gotemplate
{{- "{{" }} $render := (or (and (hasKey . "render") (index . "render")) (dict)) {{ "}}" -}}
language: {{ "{{" }} if hasKey $render "language" {{ "}}" }}{{ "{{" }} index $render "language" {{ "}}" }}{{ "{{" }} else {{ "}}" }}en{{ "{{" }} end {{ "}}" }}
```

## Booleans, Numbers, and Strings

- Strings: wrap in quotes.
- Booleans/Numbers: don’t quote.

```gotemplate
include_quotes: {{ "{{" }} if hasKey . "include_quotes" {{ "}}" }}{{ "{{" }} index . "include_quotes" {{ "}}" }}{{ "{{" }} else {{ "}}" }}true{{ "{{" }} end {{ "}}" }}
length_seconds: {{ "{{" }} if hasKey . "length_seconds" {{ "}}" }}{{ "{{" }} index . "length_seconds" {{ "}}" }}{{ "{{" }} else {{ "}}" }}20{{ "{{" }} end {{ "}}" }}
title: "{{ "{{" }} if hasKey . "note_title" {{ "}}" }}{{ "{{" }} index . "note_title" {{ "}}" }}{{ "{{" }} else {{ "}}" }}<Video Title>{{ "{{" }} end {{ "}}" }}"
```

## Arrays and Dictionaries

Create with `list` and `dict`. Guard before access.

```gotemplate
{{- "{{" }} $tags := (or (and (hasKey . "tags") (index . "tags")) (list)) {{ "}}" -}}
{{- "{{" }} range $tags {{ "}}" }}- {{ "{{" }} . {{ "}}" }}{{- "{{" }} end {{ "}}" -}}
```

## Escaping Literal `{{` and `}}`

When you need the template delimiters as literal text (e.g., documentation), nest escaping:

```gotemplate
{{ "{{" }} .note_title {{ "}}" }}
```

For larger blocks, prefer an included snippet that’s pre-escaped for readability.

## Showing examples inside a live template (comment-safe)

When you’re already inside a Go Template file and want to include an example that should not execute, wrap it in a Go template comment. Content inside the comment is not evaluated.

```gotemplate
{{ "{{" }} {{ "\"{{/*\"" }} {{ "}}" }} example (display-only) {{ "{{" }} {{ "\"*/}}\"" }} {{ "}}" }}
```

## Includes, Partials, and Data Passing

- Use `includeTemplate` with explicit data.
- Build a data object via `dict` to avoid leaking unintended keys.

```gotemplate
{{ "{{" }} includeTemplate "config/ai/templates/general/decision-record-template.md.tmpl" (dict "dr" $dr) {{ "}}" }}
```

## Reusable Locals

Assign once; reuse to keep templates readable and efficient.

```gotemplate
{{- "{{" }} $has := hasKey {{ "}}" -}}
{{- "{{" }} $idx := index {{ "}}" -}}
{{- "{{" }} if and ($has . "render") ($has ($idx . "render") "language") {{ "}}" -}}
  {{ "{{" }} $idx ($idx . "render") "language" {{ "}}" }}
{{- "{{" }} else {{ "}}" -}}en{{- "{{" }} end {{ "}}" -}}
```

## Control Flow Tips

- `and`, `or`, `not`, `eq`, `ne` are available.
- Prefer explicit `if` blocks for clarity and safety.

## Common Pitfalls and Fixes

- ❌ `.key | default ...` on map-based dots → ✅ `if hasKey` + `index`.
- ❌ Accessing nested keys without guarding parent → ✅ guard each level or use `(dict)` fallback.
- ❌ Quoting booleans/numbers → ✅ only quote strings.
- ❌ Assuming Sprig funcs exist → ✅ verify with `chezmoi execute-template '{{ list 1 }}'` quick checks.
- ❌ Forgetting to escape literal `{{` `}}` → ✅ use `{{ "{{" }}` and `{{ "}}" }}`.

## Testing Templates Locally

Dry run apply:

```sh
chezmoi apply --dry-run --verbose
```

Execute a template file directly (stdin):

```sh
chezmoi execute-template < path/to/template.tmpl
```

Smoke-test a function quickly:

```sh
chezmoi execute-template '{{"{{"}} if hasKey (dict "a" 1) "a" {{"}}"}} ok {{"{{"}} else {{ "}}" }} no {{ "{{" }} end {{ "}}" }}'
```

## Reference Patterns (Copy/Paste)

### Safe render block

```gotemplate
render:
  summarize_level: {{ "{{" }} if hasKey . "summarize_level" {{ "}}" }}{{ "{{" }} index . "summarize_level" {{ "}}" }}{{ "{{" }} else {{ "}}" }}standard{{ "{{" }} end {{ "}}" }}
  include_quotes: {{ "{{" }} if hasKey . "include_quotes" {{ "}}" }}{{ "{{" }} index . "include_quotes" {{ "}}" }}{{ "{{" }} else {{ "}}" }}true{{ "{{" }} end {{ "}}" }}
  include_action_items: {{ "{{" }} if hasKey . "include_action_items" {{ "}}" }}{{ "{{" }} index . "include_action_items" {{ "}}" }}{{ "{{" }} else {{ "}}" }}true{{ "{{" }} end {{ "}}" }}
  include_glossary: {{ "{{" }} if hasKey . "include_glossary" {{ "}}" }}{{ "{{" }} index . "include_glossary" {{ "}}" }}{{ "{{" }} else {{ "}}" }}false{{ "{{" }} end {{ "}}" }}
  include_code: {{ "{{" }} if hasKey . "include_code" {{ "}}" }}{{ "{{" }} index . "include_code" {{ "}}" }}{{ "{{" }} else {{ "}}" }}false{{ "{{" }} end {{ "}}" }}
  language: {{ "{{" }} if hasKey . "language" {{ "}}" }}{{ "{{" }} index . "language" {{ "}}" }}{{ "{{" }} else {{ "}}" }}"en"{{ "{{" }} end {{ "}}" }}
  scope_focus: {{ "{{" }} if hasKey . "scope_focus" {{ "}}" }}{{ "{{" }} index . "scope_focus" {{ "}}" }}{{ "{{" }} else {{ "}}" }}""{{ "{{" }} end {{ "}}" }}
```

### Nested with local

```gotemplate
{{- "{{" }} $render := (or (and (hasKey . "render") (index . "render")) (dict)) {{ "}}" -}}
language: {{ "{{" }} if hasKey $render "language" {{ "}}" }}{{ "{{" }} index $render "language" {{ "}}" }}{{ "{{" }} else {{ "}}" }}en{{ "{{" }} end {{ "}}" }}
```

---

Footnote: In chezmoi, templates run with Go’s `text/template`. Map key access via `.key` fails if the key isn’t present. Guard with `hasKey` and retrieve with `index` so defaults can apply.
