---
workflow: "Systems Thinking"
slug: "systems-thinking"
description: "View complex problems as interconnected systems rather than isolated events."
use: "When understanding economics, ecology, organizations, or any complex domain where parts interact and influence each other."
role: "Systems Analyst"
triggers: ["manual"]
concurrency:
  group: "systems-thinking"
  cancel_in_progress: false
retries:
  max: 0
  backoff_secs: 0
safety:
  dry_run: false
  confirm_dangerous_ops: false
artifacts: ["systems-analysis.md"]
permissions: ["read"]

tools:
  - name: "analysis"
    description: "Analyze systems and interconnections"
    inputs:
      - name: "system"
        type: "string"
        required: true
        description: "The system or domain to analyze"
      - name: "problem"
        type: "string"
        required: false
        description: "Specific problem or symptom within the system"
    outputs:
      - name: "analysis"
        type: "string"
        description: "System structure, feedback loops, and leverage points"
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

# Systems Thinking

## Goal

View complex problems as interconnected systems with feedback loops, delays, and leverage points. This approach:

- Reveals root causes hidden by linear thinking
- Identifies unintended consequences of interventions
- Finds high-leverage points for change
- Avoids treating symptoms instead of causes

Success criteria: A clear map of system structure, feedback loops, and leverage points for intervention.

### Role

- **Systems Analyst**: Map the system's structure, identify feedback loops, and find leverage points.
- Distinguish between symptoms and root causes.
- Recognize delays and unintended consequences.

## I/O

### Context

- The system or domain to analyze.
- Specific problems or symptoms within the system.
- Key actors, resources, and relationships.

#### Required Context

- **System**: The domain or system to analyze (e.g., organizational culture, supply chain, ecosystem).

#### Suggested Context

- Specific problems or symptoms you're observing.
- Key stakeholders and their incentives.
- Historical patterns or cycles.

### Inputs

Parameterization for systems analysis.

```yaml
schema:
  inputs:
    - name: system
      type: string
      required: true
      description: "The system or domain to analyze"
      example: "Software development team productivity"
    - name: problem
      type: string
      required: false
      description: "Specific problem or symptom within the system"
      example: "Velocity declining despite adding more developers"
```

### Outputs

System analysis with structure and leverage points.

```yaml
schema:
  outputs:
    - name: system_structure
      type: array<string>
      required: true
      description: "Key components and relationships"
    - name: feedback_loops
      type: array<string>
      required: true
      description: "Reinforcing and balancing loops"
    - name: delays
      type: array<string>
      required: true
      description: "Time delays that affect system behavior"
    - name: leverage_points
      type: array<string>
      required: true
      description: "High-impact intervention points"
    - name: unintended_consequences
      type: array<string>
      required: false
      description: "Potential side effects of interventions"
```

## Operation

Phased systems analysis.

1. **Define System Boundaries**: What's inside and outside the system?
2. **Map Components**: Identify key elements and actors.
3. **Identify Relationships**: How do components influence each other?
4. **Find Feedback Loops**: What reinforces or balances the system?
5. **Identify Delays**: Where do time lags affect behavior?
6. **Locate Leverage Points**: Where can small changes have large effects?
7. **Anticipate Consequences**: What unintended effects might occur?

### Tools

Declare the tools used at each step.

```yaml
manifest:
  steps:
    - name: define_boundaries
      uses: analysis
      constraints:
        - "Clearly state what's in and out of the system"
    - name: map_components
      uses: analysis
      constraints:
        - "Identify all key elements and actors"
    - name: identify_relationships
      uses: analysis
      constraints:
        - "Show how components influence each other"
    - name: find_feedback_loops
      uses: analysis
      constraints:
        - "Distinguish reinforcing loops (growth) from balancing loops (stability)"
    - name: locate_leverage_points
      uses: analysis
      constraints:
        - "Find high-impact intervention points"
```

### Instructions

Non-negotiable execution rules.

- **Think in Loops**: Focus on feedback loops, not linear cause-and-effect.
- **Identify Delays**: Time lags often cause counterintuitive behavior.
- **Avoid Linear Thinking**: Don't assume A causes B; look for circular relationships.
- **Anticipate Consequences**: Interventions often create unintended side effects.
- **Find Leverage**: Small changes in the right place can transform the system.

### Templates

#### Input Template

```markdown
# Systems Analysis

**System**: [The domain or system to analyze]

**Problem/Symptom**: [What's not working as expected?]

**Key Stakeholders**: [Who are the main actors?]
```

#### Output Template

```markdown
# Systems Analysis: [System]

## System Structure
- [Component 1]: [Role and relationships]
- [Component 2]: [Role and relationships]

## Feedback Loops
- **Reinforcing Loop**: [Description and impact]
- **Balancing Loop**: [Description and impact]

## Time Delays
- [Delay 1]: [Where it occurs and its effect]
- [Delay 2]: [Where it occurs and its effect]

## Leverage Points (Highest to Lowest Impact)
1. [Point 1]: [Why it's high-leverage]
2. [Point 2]: [Why it's high-leverage]

## Unintended Consequences
- [If we intervene at Point 1]: [Potential side effects]
- [If we intervene at Point 2]: [Potential side effects]

## Recommendations
- [Action 1]: [Based on system analysis]
```

## Design By Contract

### Preconditions

- System boundaries are clearly defined.
- Key components and relationships are identified.

### Postconditions

- Feedback loops are explicitly mapped.
- Leverage points are identified with clear rationale.

### Invariants

- Analysis avoids linear thinking.
- Unintended consequences are anticipated.

### Assertions

```pseudo
assert(system_boundaries are clear)
assert(feedback_loops are identified)
assert(leverage_points differ from obvious interventions)
```

### Contracts

- **Structure Contract**: System components and relationships are clearly documented.
- **Loop Contract**: Feedback loops are explicitly identified and explained.
- **Leverage Contract**: Intervention points are ranked by impact.
