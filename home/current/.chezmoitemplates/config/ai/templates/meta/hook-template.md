---
hook: ""   # Hook name
slug: ""   # kebab-case id
# Fill these fields before first use.
description: ""  # One-sentence purpose of this hook
use: ""          # When to run; event or phase
role: "Event Hook"
event: ""        # e.g., pre-commit, post-merge, file-change
aliases: [""]
targets: [""]    # files/globs observed or affected
conditions: [""] # predicates to run
entrypoint: ""    # script or command
side_effects: [""] # write paths or external calls
safety:
  dry_run: true
  confirm_dangerous_ops: true
  timeouts_secs: 60
retries:
  max: 0
  backoff_secs: 0
tools:
  - name: ""
    description: ""
    inputs:
      - name: ""
        type: ""
        required: true
        description: ""
    outputs:
      - name: ""
        type: ""
        description: ""
version: 1.0.0
owner: "https://github.com/levonk"
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
tags: ["hook"]
---

# <HOOK_NAME>

## Goal
- Describe the event-driven outcome and success criteria.

### Role
- Reactive action bound to event lifecycle; clear boundaries.

## i/o

### Context
- Event source, environment, and permissions.

#### Required Context

#### Suggested Context

### Inputs
- Event payload and configuration.

```yaml
schema:
  inputs:
    - name: payload
      type: object
      required: true
    - name: config
      type: object
      required: false
```

### Outputs
- Side effects performed; logs and status.

```yaml
schema:
  outputs:
    - name: status
      type: enum
      enum: ["handled", "skipped", "failed"]
      required: true
    - name: changed_files
      type: array<string>
      required: false
```

## Operation

1. Initialize: validate event; check conditions.
2. Act: run entrypoint; capture outputs; limit side effects to targets.
3. Verify: ensure invariants; run quick lints/tests if relevant.
4. Deliver: report status; log artifacts.

### Tools
- List tools used by the hook and constraints.

### Instructions
- Must be fast; avoid long-running operations on synchronous hooks.
- Respect dry-run; confirm dangerous operations.

### Templates

#### Input Templates

```markdown
<!-- hook-input.md -->
# Hook Invocation
- Event: <name>
- Payload: <summary>
- Conditions: <list>
```

#### Output Templates

```markdown
<!-- hook-summary.md -->
# Hook Summary
- Event: <name>
- Status: <handled|skipped|failed>
- Effects: <files/paths>
```

## Design By Contract

### Preconditions
- Event payload conforms to schema; entrypoint available.

### Postconditions
- Side effects limited to declared targets; status reported.

### Invariants
- Idempotent when re-run on the same payload.

### Assertions
- Abort if conditions not met; abort if timeout exceeded.

```pseudo
assert(check(conditions), "Hook conditions not met")
status = run(entrypoint)
assert(status in {handled, skipped, failed})
```

### Contracts
- Event Contracts: schema and validation.
- Side-effect Contracts: allowed paths and resources.
- Timeout Contracts: hard limits with graceful cancellation.

<!-- vim: set ft=markdown -->
