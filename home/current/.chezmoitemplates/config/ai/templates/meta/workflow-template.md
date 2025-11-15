---
workflow: ""  # Workflow name
slug: ""      # kebab-case id
# Fill these fields before first use.
description: ""  # One-sentence purpose of this workflow
use: ""          # When to run this workflow; trigger scenario
role: "Orchestrator"
aliases: [""]
triggers: [""]   # manual, schedule, event (push, pr, tag)
concurrency:
  group: ""
  cancel_in_progress: true
retries:
  max: 0
  backoff_secs: 0
safety:
  dry_run: true
  confirm_dangerous_ops: true
artifacts: [""]  # produced files/paths
permissions: [""]
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
  terminate: ""   # when to abort (condition or timeout)
date:
  created: ""
  updated: ""
tags: ["ai/workflow"]
---

# <WORKFLOW_NAME>

## Goal
- Describe the end-to-end outcome and success criteria.

### Role
- Coordination of tools and steps; state management boundaries.

## i/o

### Context
- Repositories, environments, secrets policy, and resource limits.

#### Required Context

#### Suggested Context

### Inputs
- Parameterization for the run; selectors and toggles.

```yaml
schema:
  inputs:
    - name: scope
      type: array<string>
      required: true
      example: ["packages/*", "docs/"]
    - name: mode
      type: string
      required: false
      enum: ["plan", "apply"]
```

### Outputs
- Artifacts, logs, and status signals.

```yaml
schema:
  outputs:
    - name: status
      type: enum
      required: true
      enum: ["completed", "in_progress", "blocked", "failed"]
    - name: changed_files
      type: array<string>
      required: false
```

## Operation
- Phased execution with gates and checkpoints.

1. Initialize: resolve scope; verify credentials; set dry-run.
2. Plan: compute actions; show diff; await confirmation if needed.
3. Apply: execute actions; batch changes; record artifacts.
4. Verify: run lints/tests; validate contracts.
5. Deliver: publish outputs; summarize and annotate.

### Tools
- Declare the tools used at each step with constraints.

```yaml
manifest:
  steps:
    - name: plan
      uses: search
      constraints:
        - "Time-bound to 20s"
    - name: apply
      uses: writer
      constraints:
        - "Atomic, reversible edits only"
```

### Instructions
- Non-negotiable execution rules.

- Default to dry-run; require confirmation for destructive ops.
- Maintain idempotency; second run after apply should be a no-op.
- Log all changed files and targets for traceability.

### Templates

#### Input Templates

```markdown
<!-- workflow-input.md -->
# Workflow Request
- Scope: <paths/globs>
- Mode: <plan|apply>
- Constraints: <notes>
```

#### Output Templates

```markdown
<!-- workflow-summary.md -->
# Workflow Summary
- Mode: <plan|apply>
- Changes: <count>
- Verification: <tests/lints>
- Trace: <artifact paths>
```

## Design By Contract

### Preconditions
- Inputs valid; required permissions and tools available.

### Postconditions
- Outputs produced; lints/tests pass; contracts met.

### Invariants
- Safe retries; no duplicate side effects.

### Assertions
- Assert dry-run for plan mode; assert confirmation before destructive apply.

```pseudo
assert(mode in {plan, apply})
if mode == plan: assert(dry_run)
```

### Contracts
- Step Contracts: each step declares inputs, outputs, timeouts.
- Safety Contracts: confirmation and rollback guarantees.
- Logging Contracts: comprehensive change logs and artifacts.

<!-- vim: set ft=markdown -->
