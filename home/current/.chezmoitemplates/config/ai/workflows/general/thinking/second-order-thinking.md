---
workflow: "Second-Order Thinking"
slug: "second-order-thinking"
description: "Think beyond immediate results to consider long-term consequences and second-order effects."
use: "When making major decisions, designing policies, or evaluating strategies where unintended consequences matter."
role: "Strategic Thinker"
triggers: ["manual"]
concurrency:
  group: "second-order-thinking"
  cancel_in_progress: false
retries:
  max: 0
  backoff_secs: 0
safety:
  dry_run: false
  confirm_dangerous_ops: false
artifacts: ["second-order-analysis.md"]
permissions: ["read"]

tools:
  - name: "analysis"
    description: "Analyze second-order consequences"
    inputs:
      - name: "decision"
        type: "string"
        required: true
        description: "The decision or action being considered"
      - name: "context"
        type: "string"
        required: false
        description: "Relevant context and stakeholders"
    outputs:
      - name: "analysis"
        type: "string"
        description: "First and second-order consequences"
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

# Second-Order Thinking

## Goal

Think beyond the immediate, obvious consequences of a decision to consider long-term, indirect effects. This approach:

- Reveals unintended consequences before they occur
- Prevents solutions that create bigger problems
- Improves decision quality by considering full impact
- Builds strategic foresight

Success criteria: Clear identification of first, second, and third-order consequences with recommendations to optimize long-term outcomes.

### Role

- **Strategic Thinker**: Look beyond immediate results to long-term implications.

- Distinguish between first-order and second-order effects.
- Trace chains of consequences across time and systems.

## I/O

### Context

- The decision or action being considered.
- Relevant stakeholders and their incentives.
- Time horizon (short-term vs. long-term).

#### Required Context

- **Decision**: The action or decision to analyze.

#### Suggested Context

- Stakeholders affected.
- Time horizon for evaluation.
- Related past decisions and their outcomes.

### Inputs

Parameterization for second-order analysis.

```yaml
schema:
  inputs:
    - name: decision
      type: string
      required: true
      description: "The decision or action being considered"
      example: "Implement a 4-day work week"
    - name: context
      type: string
      required: false
      description: "Relevant context and stakeholders"
      example: "Tech company with 500 employees; competitive market"
```

### Outputs

Second-order analysis with consequences.

```yaml
schema:
  outputs:
    - name: first_order_effects
      type: array<string>
      required: true
      description: "Immediate, obvious consequences"
    - name: second_order_effects
      type: array<string>
      required: true
      description: "Indirect consequences of first-order effects"
    - name: third_order_effects
      type: array<string>
      required: false
      description: "Consequences of second-order effects"
    - name: unintended_consequences
      type: array<string>
      required: true
      description: "Unexpected negative or positive effects"
    - name: recommendations
      type: array<string>
      required: false
      description: "How to optimize for long-term outcomes"
```

## Operation

Phased consequence analysis.

1. **State the Decision**: Clearly define the action being considered.
2. **Identify First-Order Effects**: What are the immediate, obvious consequences?
3. **Trace Second-Order Effects**: What happens as a result of first-order effects?
4. **Explore Third-Order Effects**: What happens as a result of second-order effects?
5. **Identify Unintended Consequences**: What unexpected effects might occur?
6. **Evaluate Long-Term Impact**: Is this decision good for long-term outcomes?
7. **Recommend Optimizations**: How can you maximize positive effects and minimize negative ones?

### Tools

Declare the tools used at each step.

```yaml
manifest:
  steps:
    - name: state_decision
      uses: analysis
      constraints:
        - "Define the decision clearly and specifically"
    - name: first_order
      uses: analysis
      constraints:
        - "Identify immediate, obvious consequences"
    - name: second_order
      uses: analysis
      constraints:
        - "Trace consequences of first-order effects"
    - name: third_order
      uses: analysis
      constraints:
        - "Explore further consequences"
    - name: unintended
      uses: analysis
      constraints:
        - "Identify unexpected effects"
```

### Instructions

Non-negotiable execution rules.

- **Think in Chains**: Each effect triggers further effects; trace the chains.
- **Consider Time**: First-order effects are immediate; second-order effects unfold over time.
- **Identify Stakeholders**: Different stakeholders experience different consequences.
- **Avoid Tunnel Vision**: Look beyond your immediate goals to broader impacts.
- **Anticipate Adaptation**: People respond to changes; anticipate how they'll adapt.

### Templates

#### Input Template

```markdown
# Second-Order Thinking Analysis

**Decision**: [The action or decision being considered]

**Stakeholders**: [Who is affected?]

**Time Horizon**: [Short-term vs. long-term]
```

#### Output Template

```markdown
# Second-Order Consequences: [Decision]

## First-Order Effects (Immediate)
- [Effect 1]: [Direct result of the decision]
- [Effect 2]: [Direct result of the decision]

## Second-Order Effects (Indirect)
- [Effect 1]: [Result of first-order effects]
- [Effect 2]: [Result of first-order effects]

## Third-Order Effects (Long-term)
- [Effect 1]: [Result of second-order effects]
- [Effect 2]: [Result of second-order effects]

## Unintended Consequences
- Positive: [Unexpected benefits]
- Negative: [Unexpected drawbacks]

## Impact by Stakeholder
- [Stakeholder 1]: [Net impact]
- [Stakeholder 2]: [Net impact]

## Long-Term Assessment
[Is this decision good for long-term outcomes?]

## Recommendations
- [Optimization 1]: [How to maximize positive effects]
- [Optimization 2]: [How to minimize negative effects]
```

## Design By Contract

### Preconditions

- Decision is clearly stated and specific.
- Stakeholders are identified.

### Postconditions

- First, second, and third-order effects are identified.
- Unintended consequences are explored.

### Invariants

- Analysis traces chains of consequences across time.
- Multiple stakeholder perspectives are considered.

### Assertions

```pseudo
assert(decision is clearly stated)
assert(second_order_effects differ from first_order_effects)
assert(unintended_consequences are identified)
```

### Contracts

- **Consequence Contract**: Effects are traced through multiple orders.
- **Stakeholder Contract**: Multiple perspectives are considered.
- **Time Contract**: Long-term implications are evaluated.
