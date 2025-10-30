---
workflow: "Devil's Advocate"
slug: "devils-advocate"
description: "Challenge assumptions and identify weaknesses in proposals, plans, or decisions through systematic critical analysis."
use: "When you need rigorous scrutiny of ideas, plans, or decisions to uncover hidden risks, logical fallacies, or overlooked perspectives."
role: "Critic & Analyst"
triggers: ["manual"]
concurrency:
  group: "devils-advocate"
  cancel_in_progress: false
retries:
  max: 0
  backoff_secs: 0
safety:
  dry_run: false
  confirm_dangerous_ops: false
artifacts: ["critique-report.md"]
permissions: ["read"]
tools:
  - name: "analysis"
    description: "Systematic critique and assumption-challenging"
    inputs:
      - name: "subject"
        type: "string"
        required: true
        description: "The proposal, plan, or decision to critique"
      - name: "context"
        type: "string"
        required: false
        description: "Background information, constraints, or stakeholders"
    outputs:
      - name: "critique"
        type: "string"
        description: "Detailed critical analysis with identified weaknesses"
version: 1.0.0
owner: "user"
status: "ready"
visibility: "internal"
compliance: []
runtime:
  duration:
    min: "2m"
    max: "15m"
    avg: "5m"
  terminate: "manual"
date:
  created: "2025-10-25"
  updated: "2025-10-25"
---

# Devil's Advocate

## Goal

Provide rigorous, systematic critique of proposals, plans, or decisions by:
- Challenging underlying assumptions and premises
- Identifying logical fallacies and weak reasoning
- Surfacing hidden risks, trade-offs, and unintended consequences
- Exploring alternative perspectives and counterarguments
- Strengthening decision-making through adversarial analysis

Success criteria: A comprehensive critique that exposes blind spots without dismissing the core idea.

### Role

- **Critic & Analyst**: Adopt an adversarial stance to systematically challenge the subject from multiple angles.
- Maintain intellectual honesty; distinguish between valid concerns and nitpicking.
- Avoid strawman arguments; engage with the strongest version of the proposal.

## I/O

### Context

- The proposal, plan, or decision under review.
- Relevant stakeholders, constraints, and success metrics.
- Historical context or precedents that inform the critique.

#### Required Context

- **Subject**: The specific proposal, plan, or decision to critique.

#### Suggested Context

- Stakeholders affected by this decision.
- Constraints or non-negotiables.
- Success metrics or desired outcomes.
- Prior decisions or related initiatives.

### Inputs

Parameterization for the critique run.

```yaml
schema:
  inputs:
    - name: subject
      type: string
      required: true
      description: "The proposal, plan, or decision to critique"
      example: "Migrate all services to Kubernetes"
    - name: context
      type: string
      required: false
      description: "Background, constraints, stakeholders"
      example: "Team has limited K8s experience; budget is fixed; 6-month timeline"
    - name: focus_areas
      type: array<string>
      required: false
      description: "Specific aspects to emphasize (e.g., cost, risk, feasibility)"
      example: ["cost", "team-readiness", "timeline"]
```

### Outputs

Critique report with structured findings.

```yaml
schema:
  outputs:
    - name: critique
      type: string
      required: true
      description: "Detailed critical analysis with identified weaknesses"
    - name: assumptions_challenged
      type: array<string>
      required: true
      description: "Key assumptions that were questioned"
    - name: risks_identified
      type: array<string>
      required: true
      description: "Potential risks or unintended consequences"
    - name: counterarguments
      type: array<string>
      required: true
      description: "Valid alternative perspectives or objections"
    - name: recommendations
      type: array<string>
      required: false
      description: "Suggestions to strengthen the proposal or mitigate risks"
```

## Operation

Phased execution with systematic critique.

1. **Clarify**: Understand the proposal, context, and stakeholders.
2. **Deconstruct**: Break down the proposal into core assumptions and claims.
3. **Challenge**: Question each assumption; identify logical gaps.
4. **Explore Risks**: Surface potential downsides, trade-offs, and unintended consequences.
5. **Counter**: Develop strong counterarguments from alternative perspectives.
6. **Synthesize**: Compile findings into a structured critique report.
7. **Recommend**: Suggest ways to strengthen the proposal or mitigate identified risks.

### Tools

Declare the tools used at each step.

```yaml
manifest:
  steps:
    - name: clarify
      uses: analysis
      constraints:
        - "Ensure complete understanding before critique"
    - name: deconstruct
      uses: analysis
      constraints:
        - "Identify all core assumptions and claims"
    - name: challenge
      uses: analysis
      constraints:
        - "Question each assumption rigorously"
    - name: explore_risks
      uses: analysis
      constraints:
        - "Think beyond obvious risks; consider second-order effects"
    - name: counter
      uses: analysis
      constraints:
        - "Develop strongest possible counterarguments"
    - name: synthesize
      uses: analysis
      constraints:
        - "Organize findings into clear, actionable critique"
```

### Instructions

Non-negotiable execution rules.

- **Intellectual Honesty**: Distinguish between valid concerns and nitpicking. Acknowledge the proposal's merits.
- **Avoid Strawman**: Engage with the strongest version of the proposal, not a weakened caricature.
- **Multi-Perspective**: Challenge from multiple angles: cost, feasibility, risk, team readiness, market fit, etc.
- **Depth Over Breadth**: Provide substantive critique, not surface-level objections.
- **Constructive**: Frame critique as an opportunity to strengthen the decision, not to dismiss it.
- **Document Assumptions**: Clearly state which assumptions you're challenging and why.

### Templates

#### Input Template

```markdown
# Devil's Advocate Request

**Subject**: [Proposal or decision to critique]

**Context**: [Background, constraints, stakeholders, timeline]

**Focus Areas** (optional): [e.g., cost, feasibility, risk, team readiness]
```

#### Output Template

```markdown
# Devil's Advocate Critique

## Summary
[One-paragraph overview of the critique]

## Assumptions Challenged
- [Assumption 1]: [Why it's questionable]
- [Assumption 2]: [Why it's questionable]

## Risks & Unintended Consequences
- [Risk 1]: [Potential impact]
- [Risk 2]: [Potential impact]

## Counterarguments
- [Perspective 1]: [Alternative view]
- [Perspective 2]: [Alternative view]

## Recommendations
- [Suggestion 1]: [How to strengthen or mitigate]
- [Suggestion 2]: [How to strengthen or mitigate]

## Conclusion
[Balanced assessment: merits and concerns]
```

## Design By Contract

### Preconditions

- Subject is clearly defined and understandable.
- Sufficient context provided to conduct meaningful critique.

### Postconditions

- Critique identifies at least 3 substantive concerns or assumptions.
- Recommendations are actionable and constructive.
- Report is balanced and acknowledges proposal merits.

### Invariants

- Critique remains objective and evidence-based.
- No personal attacks or dismissive language.
- Alternative perspectives are explored fairly.

### Assertions

```pseudo
assert(subject is not empty)
assert(critique identifies multiple perspectives)
assert(recommendations are constructive)
```

### Contracts

- **Analysis Contract**: Each critique step declares assumptions challenged, risks identified, and counterarguments developed.
- **Quality Contract**: Critique is substantive, balanced, and actionable.
- **Delivery Contract**: Report includes structured findings and recommendations.
