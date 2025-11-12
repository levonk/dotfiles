---
snippet: ""  # Snippet name
slug: ""     # kebab-case id
# Fill these fields before first use.
description: ""  # One-sentence purpose of this snippet
use: ""          # When to insert this snippet; scenario
role: "Code Snippet"
language: ""     # e.g., typescript, python, bash
scope: [""]      # editor, shell, tool; or file globs
prefix: ""       # trigger text
placeholders:
  - name: ""
    description: ""
    default: ""
examples:
  usage: [""]
  rendered: [""]
tags: [""]
version: 1.0.0
owner: ""
status: ""     # draft, ready, deprecated
visibility: "" # public, internal
compliance: [""]
runtime:
  duration:
    min: ""
    max: ""
    avg: ""
  terminate: ""
date:
  created: ""
  updated: ""
---

# <SNIPPET_NAME>

## Goal
- Provide a high-quality, reusable code/document block with clear intent.

### Role
- Fast insertion of proven patterns; avoid anti-patterns.

## i/o

### Context
- Editor/tool compatibility, language version, and dependencies.

#### Required Context

#### Suggested Context

### Inputs
- Placeholder values and context-derived variables.

```yaml
schema:
  inputs:
    - name: values
      type: object
      required: false
```

### Outputs
- Rendered snippet block; optionally a file if used as a template.

```yaml
schema:
  outputs:
    - name: block
      type: string
      required: true
```

## Operation

1. Initialize: resolve context (language, filetype); validate placeholders.
2. Render: substitute placeholders; format code.
3. Verify: run formatter/linter where applicable.
4. Deliver: insert or write; provide usage notes.

### Tools
- Formatters/linters for the language; snippet engine integration.

### Instructions
- Prefer minimal and modern language idioms; include imports only if needed.
- Keep 80-100 column width where practical; add links to docs when helpful.

### Templates

#### Input Templates

```markdown
<!-- snippet-input.md -->
# Snippet Request
- Language: <lang>
- Prefix: <trigger>
- Placeholders:
  - <name>: <value>
```

#### Output Templates

```markdown
<!-- snippet-summary.md -->
# Snippet Summary
- Trigger: <prefix>
- Example:
```<lang>
<rendered>
```
```

## Design By Contract

### Preconditions
- Language and scope supported; placeholders recognized.

### Postconditions
- Rendered snippet compiles/formats where applicable.

### Invariants
- Insertion is idempotent when repeated at the same location (no duplicates if guarded).

### Assertions
- Assert no unresolved placeholders remain.

```pseudo
assert(!contains(rendered, "${"), "Unresolved placeholders")
```

### Contracts
- Language Contracts: versions, formatters, and imports.
- Integration Contracts: editor/tool compatibility.
