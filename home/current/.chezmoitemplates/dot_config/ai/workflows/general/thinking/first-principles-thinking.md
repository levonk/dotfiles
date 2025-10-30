---
workflow: "First Principles Thinking"
slug: "first-principles-thinking"
description: "Break down complex problems into foundational elements and rebuild solutions from the ground up."
use: "When facing seemingly impossible problems, challenging industry dogma, or innovating beyond incremental improvements."
role: "Deconstructionist & Innovator"
triggers: ["manual"]
concurrency:
  group: "first-principles-thinking"
  cancel_in_progress: false
retries:
  max: 0
  backoff_secs: 0
safety:
  dry_run: false
  confirm_dangerous_ops: false
artifacts: ["first-principles-analysis.md"]
permissions: ["read"]

tools:
  - name: "deconstruction"
    description: "Break down problems to foundational elements"
    inputs:
      - name: "problem"
        type: "string"
        required: true
        description: "The problem or challenge to deconstruct"
      - name: "context"
        type: "string"
        required: false
        description: "Current constraints, assumptions, or industry practices"
    outputs:
      - name: "analysis"
        type: "string"
        description: "Foundational elements and novel solutions"
version: 1.0.0
owner: "user"
status: "ready"
visibility: "internal"
compliance: []
runtime:
  duration:
    min: "5m"
    max: "20m"
    avg: "10m"
  terminate: "manual"
date:
  created: "2025-10-25"
  updated: "2025-10-25"
---

# First Principles Thinking

## Goal

Deconstruct complex problems into their most basic, foundational elements and rebuild solutions from the ground up. This approach:

- Challenges industry dogma and "the way things are done"
- Enables radical innovation beyond incremental improvements
- Solves problems that seem impossible under conventional thinking
- Avoids the trap of reasoning by analogy

Success criteria: Novel solutions that emerge from fundamental truths, not inherited assumptions.

### Role

- **Deconstructionist & Innovator**: Break down problems to their essence and rebuild without inherited constraints.
- Question every assumption, especially those that seem obvious.
- Distinguish between fundamental truths and industry conventions.

## I/O

### Context

- The problem or challenge to deconstruct.
- Current industry practices and assumptions.
- Constraints and limitations (real vs. assumed).

#### Required Context

- **Problem**: The specific challenge to approach from first principles.

#### Suggested Context

- Current solutions and their limitations.
- Industry conventions and why they exist.
- Constraints that are real vs. assumed.

### Inputs

Parameterization for first principles analysis.

```yaml
schema:
  inputs:
    - name: problem
      type: string
      required: true
      description: "The problem or challenge to deconstruct"
      example: "How to make electric vehicles more affordable"
    - name: context
      type: string
      required: false
      description: "Current constraints, assumptions, or industry practices"
      example: "Traditional automakers use centralized battery packs; EVs are expensive due to battery costs"
```

### Outputs

Foundational analysis with novel solutions.

```yaml
schema:
  outputs:
    - name: fundamental_truths
      type: array<string>
      required: true
      description: "Core facts that cannot be disputed"
    - name: inherited_assumptions
      type: array<string>
      required: true
      description: "Assumptions inherited from industry or convention"
    - name: questioned_assumptions
      type: array<string>
      required: true
      description: "Assumptions that may not be necessary"
    - name: novel_solutions
      type: array<string>
      required: true
      description: "Solutions built from first principles"
    - name: implications
      type: array<string>
      required: false
      description: "Broader implications of first principles solutions"
```

## Operation

Phased deconstruction and reconstruction.

1. **Define Problem**: Clearly state the problem without inherited solutions.
2. **Identify Fundamental Truths**: What facts are immutable and universal?
3. **List Inherited Assumptions**: What does the industry assume to be true?
4. **Question Assumptions**: Which assumptions are necessary? Which are arbitrary?
5. **Identify Constraints**: Distinguish between real constraints and assumed ones.
6. **Rebuild from Scratch**: Using only fundamental truths, design a solution.
7. **Explore Implications**: What becomes possible with this new approach?

### Tools

Declare the tools used at each step.

```yaml
manifest:
  steps:
    - name: define_problem
      uses: deconstruction
      constraints:
        - "State the problem without referencing current solutions"
    - name: fundamental_truths
      uses: deconstruction
      constraints:
        - "Include only immutable facts, not opinions"
    - name: inherited_assumptions
      uses: deconstruction
      constraints:
        - "List what the industry takes for granted"
    - name: question_assumptions
      uses: deconstruction
      constraints:
        - "Challenge each assumption; ask 'Why must this be true?'"
    - name: rebuild
      uses: deconstruction
      constraints:
        - "Design solutions using only fundamental truths"
```

### Instructions

Non-negotiable execution rules.

- **Start with Fundamentals**: Begin with immutable facts, not industry practice.
- **Question Everything**: Even obvious assumptions may be arbitrary.
- **Avoid Analogy**: Don't reason "because that's how it's done elsewhere."
- **Identify Real Constraints**: Distinguish between physical laws and business conventions.
- **Think Radically**: Allow solutions that would disrupt existing industries.

### Templates

#### Input Template

```markdown
# First Principles Analysis

**Problem**: [State the problem without referencing current solutions]

**Current Industry Approach**: [How is this typically solved?]

**Constraints**: [What are the real limitations?]
```

#### Output Template

```markdown
# First Principles Deconstruction: [Problem]

## Fundamental Truths
- [Truth 1]: [Why this is immutable]
- [Truth 2]: [Why this is immutable]

## Inherited Assumptions
- [Assumption 1]: [What the industry assumes]
- [Assumption 2]: [What the industry assumes]

## Questioned Assumptions
- [Assumption 1]: [Why it may not be necessary]
- [Assumption 2]: [Why it may not be necessary]

## Real vs. Assumed Constraints
- Real Constraints: [Physical laws, economics]
- Assumed Constraints: [Industry conventions, "the way it's always been done"]

## Novel Solutions (Built from First Principles)
- [Solution 1]: [How it works, why it's different]
- [Solution 2]: [How it works, why it's different]

## Implications
- [Implication 1]: [What becomes possible]
- [Implication 2]: [What becomes possible]
```

## Design By Contract

### Preconditions

- Problem is clearly defined without reference to current solutions.
- Fundamental truths are identified and validated.

### Postconditions

- Novel solutions emerge that differ significantly from industry practice.
- Solutions are grounded in fundamental truths, not assumptions.

### Invariants

- Analysis avoids reasoning by analogy.
- Inherited assumptions are explicitly identified and questioned.

### Assertions

```pseudo
assert(problem is stated without current solutions)
assert(fundamental_truths are immutable and universal)
assert(novel_solutions differ from industry practice)
```

### Contracts

- **Deconstruction Contract**: Each level of analysis is clearly documented.
- **Innovation Contract**: Solutions are novel and grounded in first principles.
- **Clarity Contract**: Reasoning is transparent and can be followed step-by-step.
