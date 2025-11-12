---
template: "" # Template name
slug: ""     # kebab-case id
# Fill these fields before first use.
description: ""  # One-sentence purpose of this template
use: ""          # When to apply or render this template
role: "Scaffold/Renderer"
engine: ""       # go-template, jinja2, mustache, etc.
outputs_to: [""] # target paths or directories
variables:
  schema:         # variable schema for rendering
    - name: ""
      type: ""
      required: true
      default: ""
      description: ""
partials: [""]   # includes/partials used
conflicts:
  strategy: ""    # skip, merge, overwrite
  backup: true
validation: [""]  # post-render checks
tools:
  - name: ""
    description: ""
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
  terminate: ""   # when to abort
date:
  created: ""
  updated: ""
---

# <TEMPLATE_NAME>

## Goal
- Describe the artifact this template generates and the definition of done.

### Role
- Provide a consistent scaffold with validated variables and safe merge behavior.

## i/o

### Context
- Rendering environment, path conventions, and policy constraints.

#### Required Context

#### Suggested Context

### Inputs
- Variable set for template rendering and optional data sources.

```yaml
schema:
  inputs:
    - name: vars
      type: object
      required: true
      example:
        service_name: payments-api
        owner: platform
```

### Outputs
- Rendered files with conflict strategy and backup policy.

```yaml
schema:
  outputs:
    - name: files
      type: array<{path: string, mode?: string}>
      required: true
      acceptance:
        - "Files created/updated at expected locations"
        - "No unmerged conflicts"
```

## Operation

1. Initialize: load variables; validate schema.
2. Plan: preview file paths and diffs (dry-run).
3. Apply: render; write with conflict strategy; backup when needed.
4. Verify: run post-render validations (lints/tests).
5. Deliver: summarize outputs; record changed files.

### Tools
- Render engine and linters/validators.

### Instructions
- Never overwrite without either backup or explicit confirmation.
- Keep generated code/docs runnable and lint-clean.

### Templates

#### Input Templates

```markdown
<!-- template-input.md -->
# Template Render Request
- Vars: <key: value>
- Target: <path>
- Strategy: <skip|merge|overwrite>
```

#### Output Templates

```markdown
<!-- template-summary.md -->
# Template Summary
- Files: <count>
- Changed: <paths>
- Validation: <results>
```

## Design By Contract

### Preconditions
- Variable schema valid; engine available; targets writable.

### Postconditions
- Files produced at target paths; validations pass.

### Invariants
- Idempotent renders with identical inputs produce identical outputs.

### Assertions
- Assert non-empty outputs; assert no path escapes.

```pseudo
assert(len(outputs.files) > 0, "No files rendered")
```

### Contracts
- Render Contracts: engine, variables, includes.
- File Contracts: conflict strategy, permissions, and backups.
