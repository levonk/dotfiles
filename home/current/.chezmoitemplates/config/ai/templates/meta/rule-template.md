---
rule: ""  # Rule name
slug: ""  # kebab-case id
# Fill these fields before first use. Keep them short and specific.
description: ""  # One-sentence purpose of this rule
use: ""          # When this rule applies; scenario or trigger
role: "Policy/Rule"  # Primary role
severity: ""     # info, warning, error, blocking
aliases: [""]
scope: [""]      # file globs, paths, or domains this rule inspects
rationale: ""    # Why this rule exists
examples:
  good: [""]
  bad:  [""]
fix:                  # If auto-fix is possible, describe how
  available: false
  strategy: ""       # e.g., rewrite, suggest, refactor
  safety: ""         # constraints and caveats
tools:                # Tools used to enforce/check this rule
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
status: ""       # draft, ready, deprecated
visibility: ""   # public, internal
compliance: [""] # e.g., GDPR, HIPAA
runtime:
  duration:
    min: ""
    max: ""
    avg: ""
  terminate: ""   # when to abort (message or condition)
date:
  created: ""     # YYYY-MM-DD
  updated: ""     # YYYY-MM-DD
tags: ["ai/rule"]
---

# <RULE_NAME>

## Goal
- Define the behavior, constraints, or structure this rule enforces.
- State measurable success; e.g., "zero high-severity violations".

### Role
- Policy gate for the specified scope; prevents undesired states.
- Boundaries; what this rule does not check.

## i/o

### Context
- Operational environment; repo layout, conventions, and policies.
- Assumptions about file types and supported languages.

#### Required Context

#### Suggested Context


### Inputs
- Source artifacts to analyze; configuration options; exceptions list.

```yaml
schema:
  inputs:
    - name: targets
      type: array<string>
      required: true
      example: ["**/*.md", "scripts/**/*.sh"]
    - name: config
      type: object
      required: false
      example:
        allowlist: ["docs/legacy/*"]
        max_line_len: 100
```

### Outputs
- Violations report and optional auto-fix patch suggestions.

```yaml
schema:
  outputs:
    - name: report
      type: json
      required: true
      acceptance:
        - "No violations above configured severity gate"
    - name: patches
      type: diff
      required: false
```

## Operation
- Flow for evaluating and reporting.

1. Initialize: load config; resolve targets; confirm preconditions.
2. Analyze: run checks; collect findings; deduplicate.
3. Fix (optional): generate safe patches; guard with dry-run.
4. Verify: re-run checks post-fix; validate gates.
5. Deliver: persist report; exit with appropriate status.

### Tools
- Declare the validators/analyzers with constraints and limits.

```yaml
manifest:
  tools:
    - name: markdownlint
      constraints:
        - "Run only on *.md"
        - "Config file: .markdownlint.jsonc"
    - name: shellcheck
      constraints:
        - "Run with -x"
```

### Instructions
- Non-negotiable execution rules.

- Enforce severity gates deterministically.
- Keep fixes minimal and reversible; always support dry-run.
- Never modify files outside the declared scope.
- Ask for clarification if ambiguity exceeds 4%.

### Templates

#### Input Templates

```markdown
<!-- rule-input.md -->
# Rule Run Request
- Targets: <glob list>
- Config Overrides: <yaml or json>
- Severity Gate: <info|warning|error|blocking>
```

#### Output Templates

```markdown
<!-- rule-summary.md -->
# Rule Summary
- Rule: <name>
- Findings: <count by severity>
- Gate: <pass|fail> (reason)
- Suggested Fixes: <yes/no>
```

## Design By Contract

### Preconditions
- Inputs resolve to existing files; config schema valid.
- Tools available and compatible versions present.

### Postconditions
- Report produced; exit code reflects gate result.
- If auto-fix applied, file integrity and tests/lints remain green.

### Invariants
- Idempotent: repeated runs without changes yield identical reports.
- Security: never exfiltrate content; respect compliance constraints.

### Assertions
- Assert target discovery > 0 unless explicitly allowed to be empty.
- Assert report conforms to schema.

```pseudo
assert(len(targets) > 0 || allow_empty, "No targets matched")
report = analyze(targets)
assert(conforms(report, outputs.schema), "Invalid report schema")
```

### Contracts
- Tool Contracts: inputs, outputs, side effects, timeouts.
- Gate Contracts: severity thresholds and exit code mapping.
- Fix Contracts: patch format, safety checks, and rollback.

<!-- vim: set ft=markdown -->
