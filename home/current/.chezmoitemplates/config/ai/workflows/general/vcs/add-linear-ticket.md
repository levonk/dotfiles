---
workflow: "Add Linear Ticket"
slug: "add-linear-ticket"
description: Create a comprehensive Linear ticket from high-level input, automatically generating detailed context, acceptance criteria, and technical specifications using a core team of three specialist agents.
use: "When you need to turn a high-level ask into a production-ready Linear ticket (or tickets)."
role: "Orchestrator"
triggers: ["manual"]
concurrency:
  group: "linear-ticket"
  cancel_in_progress: true
retries:
  max: 0
  backoff_secs: 0
safety:
  dry_run: true
  confirm_dangerous_ops: true
artifacts: ["urls", "ticket_ids"]
permissions: ["linear:create:issues"]
tools:
  - name: linear-mcp
    description: "Create and update issues in Linear"
    inputs:
      - name: title
        type: string
        required: true
        description: "Ticket title"
      - name: description
        type: markdown
        required: true
        description: "Ticket body"
    outputs:
      - name: url
        type: string
        description: "URL of created Linear ticket"
version: 1.0.0
owner: "ai-platform"
status: "ready"
visibility: "internal"
compliance: [""]
runtime:
  duration:
    min: ""
    max: ""
    avg: ""
  terminate: "timeout(120s)"
date:
  created: "2025-09-13"
  updated: "2025-09-13"
---

# Add Linear Ticket

## Goal

- Transform a high-level request into one or more Linear tickets with clear context, acceptance criteria, and pragmatic estimates.
- Prefer a single ticket if ≤ 2 days effort; otherwise split into 2–3 coherent tickets.

## Mission

Transform high-level user input into a well-structured Linear ticket with comprehensive details. This command uses a core team of three agents (`product-manager`, `ux-designer`, `senior-software-engineer`) to handle all feature planning and specification in parallel. It focuses on **pragmatic startup estimation** to ensure tickets are scoped for rapid, iterative delivery.

**Pragmatic Startup Philosophy**:

- 🚀 **Ship Fast**: Focus on working solutions over perfect implementations.
- 💡 **80/20 Rule**: Deliver 80% of the value with 20% of the effort.
- 🎯 **MVP First**: Define the simplest thing that could possibly work.

**Smart Ticket Scoping**: Automatically breaks down large work into smaller, shippable tickets if the estimated effort exceeds 2 days.

**Important**: This command ONLY creates the ticket(s). It does not start implementation or modify any code.

## i/o

### Inputs

```yaml
schema:
  inputs:
    - name: request
      type: string
      required: true
      example: "Add a health check endpoint to the API"
    - name: depth
      type: enum
      required: false
      enum: ["LIGHT", "STANDARD", "DEEP"]
    - name: splitting
      type: enum
      required: false
      enum: ["auto", "single", "multi"]
```

### Outputs

```yaml
schema:
  outputs:
    - name: tickets
      type: array<object>
      required: true
      fields:
        - url: string
        - id: string
        - title: string
    - name: summary
      type: markdown
      required: true
```

## Core Agent Workflow

For any feature request that isn't trivial (i.e., not LIGHT), this command follows a strict parallel execution rule using the core agent trio.

### The Core Trio (Always Run in Parallel)

- **`product-manager`**: Defines the "Why" and "What." Focuses on user stories, business context, and acceptance criteria.
- **`ux-designer`**: Defines the "How" for the user. Focuses on user flow, states, accessibility, and consistency.
- **`senior-software-engineer`**: Defines the "How" for the system. Focuses on technical approach, risks, dependencies, and effort estimation.

### Parallel Execution Pattern

```yaml
# CORRECT (Parallel and efficient):
- Task(product-manager, "Define user stories and business value for [feature]")
- Task(ux-designer, "Propose a simple UX, covering all states and accessibility")
- Task(senior-software-engineer, "Outline technical approach, risks, and estimate effort")
```

-----

## Ticket Generation Process

### 1) Smart Research Depth Analysis

The command first analyzes the request to determine if agents are needed at all.

LIGHT Complexity → NO AGENTS

- For typos, simple copy changes, minor style tweaks.
- Create the ticket immediately.
- Estimate: <2 hours.

STANDARD / DEEP Complexity → CORE TRIO OF AGENTS

- For new features, bug fixes, and architectural work.
- The Core Trio is dispatched in parallel.
- The depth (Standard vs. Deep) determines the scope of their investigation.

**Override Flags (optional)**:

- `--light`: Force minimal research (no agents).
- `--standard` / `--deep`: Force investigation using the Core Trio.
- `--single` / `--multi`: Control ticket splitting.

### 2\) Scaled Investigation Strategy

#### LIGHT Research Pattern (Trivial Tickets)

NO AGENTS NEEDED.

1. Generate ticket title and description directly from the request.
2. Set pragmatic estimate (e.g., 1 hour).
3. Create ticket and finish.

#### STANDARD Research Pattern (Default for Features)

The Core Trio is dispatched with a standard scope:

- **`product-manager`**: Define user stories and success criteria for the MVP.
- **`ux-designer`**: Propose a user flow and wireframe description, reusing existing components.
- **`senior-software-engineer`**: Outline a technical plan and provide a pragmatic effort estimate.

#### DEEP Spike Pattern (Complex or Vague Tickets)

The Core Trio is dispatched with a deeper scope:

- **`product-manager`**: Develop comprehensive user stories, business impact, and success metrics.
- **`ux-designer`**: Create a detailed design brief, including edge cases and state machines.
- **`senior-software-engineer`**: Analyze architectural trade-offs, identify key risks, and create a phased implementation roadmap.

### 3\) Generate Ticket Content

Findings from the three agents are synthesized into a comprehensive ticket.

#### Description Structure

```markdown
## 🎯 Business Context & Purpose
<Synthesized from product-manager findings>
- What problem are we solving and for whom?
- What is the expected impact on business metrics?

## 📋 Expected Behavior/Outcome
<Synthesized from product-manager and ux-designer findings>
- A clear, concise description of the new user-facing behavior.
- Definition of all relevant states (loading, empty, error, success).

## 🔬 Research Summary
**Investigation Depth**: <LIGHT|STANDARD|DEEP>
**Confidence Level**: <High|Medium|Low>

### Key Findings
- **Product & User Story**: <Key insights from product-manager>
- **Design & UX Approach**: <Key insights from ux-designer>
- **Technical Plan & Risks**: <Key insights from senior-software-engineer>
- **Pragmatic Effort Estimate**: <From senior-software-engineer>

## ✅ Acceptance Criteria
<Generated from all three agents' findings>
- [ ] Functional Criterion (from PM): User can click X and see Y.
- [ ] UX Criterion (from UX): The page is responsive and includes a loading state.
- [ ] Technical Criterion (from Eng): The API endpoint returns a `201` on success.
- [ ] All new code paths are covered by tests.

## 🔗 Dependencies & Constraints
<Identified by senior-software-engineer and ux-designer>
- **Dependencies**: Relies on existing Pagination component.
- **Technical Constraints**: Must handle >10K records efficiently.

## 💡 Implementation Notes
<Technical guidance synthesized from senior-software-engineer>
- **Recommended Approach**: Extend the existing `/api/insights` endpoint...
- **Potential Gotchas**: Query performance will be critical; ensure database indexes are added.
```

### 4\) Smart Ticket Creation

- **If total estimated effort is ≤ 2 days**: A single, comprehensive ticket is created.
- **If total estimated effort is \> 2 days**: The work is automatically broken down into 2-3 smaller, interconnected tickets (e.g., "Part 1: Backend API," "Part 2: Frontend UI"), each with its own scope and estimate.

### 5\) Output & Confirmation

The command finishes by returning the URL(s) of the newly created ticket(s) in Linear.

## Operation

1. Initialize: parse inputs; set depth and splitting mode (defaults: depth=STANDARD, splitting=auto).
2. Plan: dispatch the core trio in parallel; define aggregation plan.
3. Apply: synthesize ticket body; create 1–3 Linear tickets accordingly.
4. Verify: ensure URLs returned; echo summary and acceptance criteria.
5. Deliver: output ticket URLs and a brief summary.

### Tools

```yaml
manifest:
  steps:
    - name: analyze
      uses: product-manager | ux-designer | senior-software-engineer
      constraints:
        - "Run in parallel"
    - name: create-tickets
      uses: linear-mcp
      constraints:
        - "Create 1–3 tickets only"
```

### Instructions

- Maintain idempotency where possible (re-run should not duplicate tickets if inputs unchanged; include a unique tag in tickets when appropriate).
- Be explicit about assumptions and unknowns; suggest a spike if confidence is low.
- Log all created ticket IDs/URLs.
