---
workflow: "Inversion"
slug: "inversion"
description: "Approach problems backward by thinking about what would guarantee failure, then avoid those things."
use: "When planning, risk management, achieving goals, or stress-testing plans to uncover non-obvious insights."
role: "Risk Strategist"
triggers: ["manual"]
concurrency:
  group: "inversion"
  cancel_in_progress: false
retries:
  max: 0
  backoff_secs: 0
safety:
  dry_run: false
  confirm_dangerous_ops: false
artifacts: ["inversion-analysis.md"]
permissions: ["read"]

tools:
  - name: "analysis"
    description: "Conduct inversion analysis"
    inputs:
      - name: "goal"
        type: "string"
        required: true
        description: "The goal or desired outcome"
      - name: "context"
        type: "string"
        required: false
        description: "Current situation and constraints"
    outputs:
      - name: "analysis"
        type: "string"
        description: "Failure modes and mitigation strategies"
version: 1.0.0
owner: "user"
status: "ready"
visibility: "internal"
compliance: []
runtime:
  duration:
    min: "5m"
    max: "15m"
    avg: "8m"
  terminate: "manual"
date:
  created: "2025-10-25"
  updated: "2025-10-25"
---

# Inversion

## Goal

Approach problems backward by asking "What would guarantee failure?" and then systematically avoiding those outcomes. This approach:

- Uncovers non-obvious risks and failure modes
- Generates insights that forward thinking misses
- Stress-tests plans and strategies
- Leads to more robust solutions

Success criteria: Comprehensive identification of failure modes and concrete mitigation strategies.

### Role

- **Risk Strategist**: Think backward to identify what could go wrong, then build safeguards.
- Distinguish between obvious and non-obvious failure modes.
- Convert failure modes into actionable prevention strategies.

## I/O

### Context

- The goal or desired outcome.
- Current situation, constraints, and resources.
- Stakeholders and their interests.

#### Required Context

- **Goal**: The objective or desired outcome.

#### Suggested Context

- Timeline and constraints.
- Available resources.
- Key stakeholders.

### Inputs

Parameterization for inversion analysis.

```yaml
schema:
  inputs:
    - name: goal
      type: string
      required: true
      description: "The goal or desired outcome"
      example: "Launch a successful product in 6 months"
    - name: context
      type: string
      required: false
      description: "Current situation and constraints"
      example: "Small team, limited budget, competitive market"
```

### Outputs

Inversion analysis with failure modes and mitigation.

```yaml
schema:
  outputs:
    - name: failure_modes
      type: array<string>
      required: true
      description: "What could cause failure"
    - name: obvious_failures
      type: array<string>
      required: true
      description: "Obvious failure modes"
    - name: non_obvious_failures
      type: array<string>
      required: true
      description: "Non-obvious failure modes"
    - name: mitigation_strategies
      type: array<string>
      required: true
      description: "How to prevent each failure mode"
    - name: early_warning_signs
      type: array<string>
      required: false
      description: "Indicators that you're heading toward failure"
```

## Operation

Phased inversion analysis.

1. **State the Goal**: Clearly define the desired outcome.
2. **Invert the Goal**: Ask "What would guarantee failure?"
3. **List Failure Modes**: Brainstorm everything that could go wrong.
4. **Categorize Failures**: Separate obvious from non-obvious failures.
5. **Identify Root Causes**: Why would each failure occur?
6. **Develop Mitigation**: How can you prevent each failure?
7. **Identify Warning Signs**: What early indicators signal you're heading toward failure?

### Tools

Declare the tools used at each step.

```yaml
manifest:
  steps:
    - name: state_goal
      uses: analysis
      constraints:
        - "Define the goal clearly and specifically"
    - name: invert_goal
      uses: analysis
      constraints:
        - "Ask 'What would guarantee failure?'"
    - name: list_failures
      uses: analysis
      constraints:
        - "Brainstorm comprehensively; include non-obvious failures"
    - name: develop_mitigation
      uses: analysis
      constraints:
        - "Each mitigation should directly prevent a failure mode"
    - name: identify_warnings
      uses: analysis
      constraints:
        - "Identify early indicators of failure"
```

### Instructions

Non-negotiable execution rules.

- **Think Backward**: Focus on failure, not success.
- **Be Comprehensive**: Include obvious and non-obvious failure modes.
- **Avoid Optimism Bias**: Don't assume "it won't happen to us."
- **Identify Root Causes**: Understand why failures would occur.
- **Create Safeguards**: Develop concrete prevention strategies.

### Templates

#### Input Template

```markdown
# Inversion Analysis

**Goal**: [The desired outcome]

**Timeline**: [When should this be achieved?]

**Constraints**: [Budget, resources, team size, market conditions]
```

#### Output Template

```markdown
# Inversion Analysis: [Goal]

## Failure Modes

### Obvious Failures
- [Failure 1]: [Why it could happen]
- [Failure 2]: [Why it could happen]

### Non-Obvious Failures
- [Failure 1]: [Why it could happen]
- [Failure 2]: [Why it could happen]

## Mitigation Strategies
- [For Failure 1]: [How to prevent it]
- [For Failure 2]: [How to prevent it]

## Early Warning Signs
- [Warning 1]: [What to watch for]
- [Warning 2]: [What to watch for]

## Stress-Test Results
[Summary of how robust the plan is against failure modes]
```

## Design By Contract

### Preconditions

- Goal is clearly defined and specific.
- Context and constraints are understood.

### Postconditions

- Comprehensive failure modes are identified.
- Mitigation strategies are concrete and actionable.

### Invariants

- Analysis includes both obvious and non-obvious failures.
- Each mitigation directly addresses a failure mode.

### Assertions

```pseudo
assert(goal is clearly stated)
assert(failure_modes include non_obvious failures)
assert(mitigation_strategies are concrete and actionable)
```

### Contracts

- **Inversion Contract**: Failure modes are systematically identified.
- **Mitigation Contract**: Each failure mode has a corresponding prevention strategy.
- **Warning Contract**: Early warning signs are identified for each failure mode.
