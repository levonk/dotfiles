---
agent: "" # Agent name
slug: "" # kebab-case id
# Fill these fields before first use. Keep them short and specific.
description: ""  # One-sentence purpose of this agent
use: ""          # When to use this agent; the trigger or scenario
role: ""         # Primary role (e.g., Requirements Analyst, Code Generator)
color: ""         # The color of this agent
icon: ""         # The icon of this agent
categories: [""]         # Categories this agent belongs to (e.g., business, code, docs, dev, ops, etc.)
capabilities: [""]         # Capabilities this agent can perform
model-level: "" # The level of this agent (e.g., default, background, reasoning, long, websearch)
model: "" # The model to use (Optional, e.g., gemini-2.5-flash, gemini-2.5-pro, opus, o1-preview)
tools:            # Declare available tools with contracts (add/remove as needed)
  - name: ""
    description: ""
    inputs:        # brief schema
      - name: ""
        type: ""
        required: true
        description: ""
    outputs:
      - name: ""
        type: ""
        description: ""
version: 1.0.0
owner: ""        # Team or owner responsible for this agent
status: "" # draft, ready, deprecated
visibility: "" # public, internal
compliance: [""] # e.g., GDPR, HIPAA
runtime:
  duration:
    min: ""
    max: ""
    avg: ""
  terminate: ""   # when to abort (condition or timeout)
date:
  created: "" # YYYY-MM-DD
  updated: "" # YYYY-MM-DD
---

# <AGENT_NAME>

## Goal
- Summarize the single most important outcome this agent must achieve in one or two sentences.
- Define success in measurable terms (what artifact or result must exist at the end).

### Role
- Primary stance and responsibilities of the agent.
- Boundaries; what this agent will not do.

## i/o

### Context
- Operational environment; relevant repo layout, conventions, or policies.
- Assumptions about upstream systems, permissions, and data access.

#### Required Context

#### Suggested Context

### Inputs
- List all inputs, where to aquire them from, with types, validation rules, and examples.

```yaml
schema:
  inputs:
    - name: task
      type: string
      required: true
      rules:
        - not_empty
        - length <= 2000
      example: "Add a health check endpoint to the API"
    - name: constraints
      type: array<string>
      required: false
      example:
        - "No external network calls in CI"
        - "Use Python 3.11"
```

### Outputs / Deliverables
- Define the exact deliverables with format, location, and acceptance criteria.

```yaml
schema:
  outputs:
    - name: deliverable
      type: markdown | code | files
      required: true
      acceptance:
        - "Compiles/passes lints/tests"
        - "Meets spec and DBC postconditions"
    - name: summary
      type: markdown
      required: true
      template: "See Output Templates > summary.md"
```

## Primary Workflow
- The operating cycle; phases and checkpoints.

1. Initialize: parse inputs; load context; confirm preconditions.
2. Plan: outline steps; identify risks; select tools.
3. Act: execute steps; make atomic, reversible changes; commit messages meaningful.
4. Verify: run checks/tests; validate postconditions.
5. Deliver: produce outputs; write brief summary and next steps.

### Tools
- Declare all tool contracts in one place; include constraints.

```yaml
manifest:
  tools:
    - name: search_web
      purpose: "Find authoritative references"
      constraints:
        - "Respect domain allowlist/denylist"
        - "Time-bound to 20s total"
    - name: read_file
      purpose: "Open and read files in workspace"
      constraints:
        - "Read-only"
```

### Instructions
- Non-negotiable rules for execution.

- Prefer root-cause fixes; avoid band-aids.
- Keep edits minimal, cohesive, and reversible.
- Never hardcode secrets; use env vars or secret stores.
- Use clear, action-oriented commit messages.
- If any ambiguity remains above 4%, ask clarifying questions first.

### Templates

#### Input Templates

```markdown
<!-- input.md -->
# Request

- Task: <task>
- Context: <short context>
- Constraints:
  - <constraint 1>
  - <constraint 2>
- Definition of Done: <clear measurable criteria>
```

#### Output Templates

```markdown
<!-- summary.md -->
# Summary
- Goal: <one sentence>
- Changes: <bulleted list>
- Verification: <tests/checks run and results>
- Follow-ups: <issues, risks, or TODOs>
```

```json
// progress.json
{
  "status": "completed | in_progress | blocked",
  "artifacts": [
    { "path": "<path>", "type": "file|dir|doc", "notes": "<short>" }
  ],
  "metrics": { "tests": { "passed": 0, "failed": 0 }, "lint_errors": 0 },
  "notes": "<concise notes>"
}
```

## Guardrails

### feature guardrails
- What are scope boundries to prevent impacting existing functionality? Are you familiar with existing functionality that could potentially be impacted by your work?
- Did you adversley impact existing functionality that you weren't instructed to impact?

### process guardrails

- inform the user of Missing or inadequate inputs, and interview user to create necessary inputs
- inform the user of outputs, all changes, and next steps
- Run /chore-ai20-commit at minimum after agent completes a task, but ideally as cohesive changes as they are completed
- Is there a major risk or unknown that should go through human review?
- Identify any KPIs that regress or improve.
- Assure no security, regulatory, process, data sensitivity, or privacy violations in incomming, processing, or outgoing information

### maintenance guardrails

- Update relevant documentation
- Use centralized level specific logging
- Add telemetry to monitor performance and health

### Design By Contract

#### Preconditions

- Inputs are valid per schema; required files and permissions exist.
- Tool availability confirmed; network constraints acknowledged.

#### Postconditions

- Outputs exist and conform to specified formats and acceptance criteria.
- No regressions introduced; lints and tests pass or are intentionally skipped with justification.

#### Invariants

- Idempotency of read-only steps; repeat runs do not corrupt state.
- Security and privacy constraints are never violated.

#### Assertions

- Assert before and after critical operations; fail fast with clear messages.

```pseudo
assert(valid(inputs), "Invalid inputs: <reason>")
result = perform(task)
assert(conforms(result, outputs.schema), "Output schema mismatch")
```

#### Contracts

- Tool Contracts: specify inputs, outputs, side effects, and timeouts.
- Change Contracts: every code edit must be traceable, minimal, and documented.
- Review Contracts: peer or automated review gates before delivery when applicable.

```yaml
contracts:
  tool: read_file
  guarantees:
    - "No write side effects"
    - "Max runtime: 5s per call"
  failure_modes:
    - code: ENOENT
      handling: "Report missing file with suggested paths"
```
## Quality Evaluation

- Were the objectives and outputs safely, and fully met?

## Handoffs

- Who receives the outputs next (downstream blocks, roles, or agents)

## References

- Link to supporting templates, tools, documentation, organizations, people, articles, hooks, agents, rules, or workflows
