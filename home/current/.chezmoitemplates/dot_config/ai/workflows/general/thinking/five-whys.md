---
workflow: "The 5 Whys"
slug: "five-whys"
description: "Root cause analysis technique that repeatedly asks 'Why?' to move past symptoms to underlying causes."
use: "When troubleshooting problems, improving processes, or solving recurring issues in manufacturing, engineering, or business."
role: "Root Cause Analyst"
triggers: ["manual"]
concurrency:
  group: "five-whys"
  cancel_in_progress: false
retries:
  max: 0
  backoff_secs: 0
safety:
  dry_run: false
  confirm_dangerous_ops: false
artifacts: ["root-cause-analysis.md"]
permissions: ["read"]

tools:
  - name: "analysis"
    description: "Conduct root cause analysis"
    inputs:
      - name: "problem"
        type: "string"
        required: true
        description: "The symptom or problem to investigate"
      - name: "context"
        type: "string"
        required: false
        description: "Background information about when and where the problem occurs"
    outputs:
      - name: "analysis"
        type: "string"
        description: "Root cause and recommended solutions"
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

# The 5 Whys

## Goal

Conduct root cause analysis by repeatedly asking "Why?" (typically five times) to move past surface-level symptoms and uncover the underlying cause of a problem. This approach:

- Prevents treating symptoms instead of causes
- Identifies systemic issues rather than one-off failures
- Leads to permanent solutions rather than temporary fixes
- Builds organizational learning

Success criteria: Identification of the true root cause and actionable solutions to prevent recurrence.

### Role

- **Root Cause Analyst**: Dig deeper with each "Why?" to uncover systemic issues.
- Distinguish between immediate causes and underlying causes.
- Avoid stopping too early; keep asking until you reach the true root.

## I/O

### Context

- The symptom or problem to investigate.
- When and where the problem occurs.
- Any relevant background or history.

#### Required Context

- **Problem**: The symptom or issue to investigate.

#### Suggested Context

- When the problem first appeared.
- How frequently it occurs.
- Who is affected.

### Inputs

Parameterization for root cause analysis.

```yaml
schema:
  inputs:
    - name: problem
      type: string
      required: true
      description: "The symptom or problem to investigate"
      example: "Website is down"
    - name: context
      type: string
      required: false
      description: "Background information about when and where the problem occurs"
      example: "Happened during peak traffic on Friday evening; affects all users"
```

### Outputs

Root cause analysis with solutions.

```yaml
schema:
  outputs:
    - name: why_chain
      type: array<string>
      required: true
      description: "The chain of 'Why?' questions and answers"
    - name: root_cause
      type: string
      required: true
      description: "The underlying cause identified"
    - name: contributing_factors
      type: array<string>
      required: false
      description: "Secondary factors that enabled the root cause"
    - name: solutions
      type: array<string>
      required: true
      description: "Recommended solutions to prevent recurrence"
```

## Operation

Phased root cause analysis.

1. **State the Problem**: Clearly describe the symptom.
2. **Ask Why #1**: Why did this happen?
3. **Ask Why #2**: Why did that cause occur?
4. **Ask Why #3**: Why did that happen?
5. **Ask Why #4**: Why did that happen?
6. **Ask Why #5**: Why did that happen?
7. **Identify Root Cause**: What is the underlying cause?
8. **Develop Solutions**: How can we prevent this from happening again?

### Tools

Declare the tools used at each step.

```yaml
manifest:
  steps:
    - name: state_problem
      uses: analysis
      constraints:
        - "Describe the symptom clearly and objectively"
    - name: ask_whys
      uses: analysis
      constraints:
        - "Keep asking 'Why?' until you reach the root cause"
        - "Typically 5 iterations, but may be more or fewer"
    - name: identify_root_cause
      uses: analysis
      constraints:
        - "Distinguish root cause from contributing factors"
    - name: develop_solutions
      uses: analysis
      constraints:
        - "Solutions should address root cause, not just symptoms"
```

### Instructions

Non-negotiable execution rules.

- **Don't Stop Too Early**: Keep asking "Why?" until you've reached the true underlying cause.
- **Avoid Blame**: Focus on systems and processes, not individuals.
- **Be Specific**: Each answer should be concrete and verifiable.
- **Multiple Causes**: Some problems have multiple root causes; identify all of them.
- **Verify Solutions**: Ensure proposed solutions actually address the root cause.

### Templates

#### Input Template

```markdown
# Root Cause Analysis: 5 Whys

**Problem**: [Describe the symptom or issue]

**When It Occurred**: [Date, time, frequency]

**Impact**: [Who is affected and how]
```

#### Output Template

```markdown
# Root Cause Analysis: [Problem]

## Why Chain

**Why 1**: [Problem statement]
**Answer**: [Immediate cause]

**Why 2**: [Why did that cause occur?]
**Answer**: [Secondary cause]

**Why 3**: [Why did that happen?]
**Answer**: [Tertiary cause]

**Why 4**: [Why did that happen?]
**Answer**: [Deeper cause]

**Why 5**: [Why did that happen?]
**Answer**: [Root cause]

## Root Cause
[The underlying cause that, if fixed, prevents recurrence]

## Contributing Factors
- [Factor 1]: [How it enabled the root cause]
- [Factor 2]: [How it enabled the root cause]

## Solutions
- [Solution 1]: [How it addresses the root cause]
- [Solution 2]: [How it addresses the root cause]

## Prevention
[How to prevent this from happening again]
```

## Design By Contract

### Preconditions

- Problem is clearly stated and specific.
- Context is provided for investigation.

### Postconditions

- Root cause is identified and distinct from symptoms.
- Solutions directly address the root cause.

### Invariants

- Analysis avoids blame and focuses on systems.
- Each "Why?" is answered with specific, verifiable information.

### Assertions

```pseudo
assert(problem is clearly stated)
assert(root_cause is distinct from symptoms)
assert(solutions address root_cause, not symptoms)
```

### Contracts

- **Analysis Contract**: Each "Why?" is answered with specific information.
- **Causation Contract**: Root cause is verified to be the underlying issue.
- **Solution Contract**: Solutions are designed to prevent recurrence.
