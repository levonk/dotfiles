---
workflow: "Consolidate Model Outcomes"
slug: "consolidate-model-outcomes"
description: "Meta-workflow to synthesize insights from multiple thinking models into comprehensive understanding and actionable recommendations."
use: "After applying multiple mental models to a problem, consolidate their outcomes to identify common themes, contradictions, and prioritized actions."
role: "Synthesizer & Decision Maker"
triggers: ["manual"]
concurrency:
  group: "consolidate-model-outcomes"
  cancel_in_progress: false
retries:
  max: 0
  backoff_secs: 0
safety:
  dry_run: false
  confirm_dangerous_ops: false
artifacts: ["consolidated-analysis.md"]
permissions: ["read"]

tools:
  - name: "synthesis"
    description: "Synthesize outcomes from multiple models"
    inputs:
      - name: "problem"
        type: "string"
        required: true
        description: "The original problem being analyzed"
      - name: "model_outcomes"
        type: "array<string>"
        required: true
        description: "Outcomes from each applied mental model"
    outputs:
      - name: "synthesis"
        type: "string"
        description: "Consolidated analysis with recommendations"
version: 1.0.0
owner: "user"
status: "ready"
visibility: "internal"
compliance: []
runtime:
  duration:
    min: "10m"
    max: "30m"
    avg: "15m"
  terminate: "manual"
date:
  created: "2025-10-25"
  updated: "2025-10-25"
---

# Consolidate Model Outcomes

## Goal

Synthesize insights from multiple applied mental models into a comprehensive understanding and actionable plan. This workflow:
- Identifies common themes across models
- Surfaces contradictions and trade-offs
- Prioritizes actions based on consensus and impact
- Creates a final report with clear recommendations

Success criteria: A consolidated analysis with prioritized actions and documented trade-offs.

### Role

- **Synthesizer & Decision Maker**: Combine insights from multiple models into coherent strategy.
- Identify patterns and contradictions.
- Make trade-off decisions based on multiple perspectives.

## I/O

### Context

- The original problem being analyzed.
- Outcomes from each applied mental model.
- Decision criteria and constraints.

#### Required Context

- **Problem**: The original problem statement.
- **Model Outcomes**: Results from applying each selected model.

#### Suggested Context

- Decision criteria or success metrics.
- Constraints or limitations.
- Stakeholder priorities.

### Inputs

Parameterization for outcome consolidation.

```yaml
schema:
  inputs:
    - name: problem
      type: string
      required: true
      description: "The original problem being analyzed"
      example: "Low team productivity and high burnout"
    - name: model_outcomes
      type: array<string>
      required: true
      description: "Outcomes from each applied mental model"
      example:
        - "Eisenhower Matrix: Identified urgent but unimportant tasks"
        - "Pareto Principle: 20% of tasks produce 80% of results"
```

### Outputs

Consolidated analysis with recommendations.

```yaml
schema:
  outputs:
    - name: common_themes
      type: array<string>
      required: true
      description: "Insights that appear across multiple models"
    - name: contradictions
      type: array<string>
      required: true
      description: "Conflicting recommendations from different models"
    - name: novel_insights
      type: array<string>
      required: true
      description: "Unique perspectives from individual models"
    - name: consolidated_summary
      type: string
      required: true
      description: "Synthesis of all insights"
    - name: prioritized_actions
      type: array<string>
      required: true
      description: "Ranked actions based on importance and impact"
    - name: trade_offs
      type: array<string>
      required: false
      description: "Acknowledged trade-offs and risks"
    - name: final_report
      type: string
      required: true
      description: "Comprehensive final report with recommendations"
```

## Operation

Phased consolidation and synthesis.

1. **Gather Outcomes**: Collect results from each applied model.
2. **Identify Overlapping Insights**: Find common themes and patterns.
3. **Surface Contradictions**: Identify conflicting recommendations.
4. **Extract Novel Insights**: Recognize unique perspectives.
5. **Synthesize & Prioritize**: Create consolidated summary and rank actions.
6. **Acknowledge Trade-offs**: Document trade-offs and risks.
7. **Document & Reflect**: Write final report and reflect on process.

### Tools

Declare the tools used at each step.

```yaml
manifest:
  steps:
    - name: gather_outcomes
      uses: synthesis
      constraints:
        - "Collect all outcomes from applied models"
    - name: identify_themes
      uses: synthesis
      constraints:
        - "Look for patterns that appear in multiple models"
    - name: surface_contradictions
      uses: synthesis
      constraints:
        - "Identify conflicting recommendations"
    - name: extract_insights
      uses: synthesis
      constraints:
        - "Recognize unique perspectives from individual models"
    - name: synthesize
      uses: synthesis
      constraints:
        - "Create consolidated summary"
    - name: prioritize_actions
      uses: synthesis
      constraints:
        - "Rank actions by importance and impact"
    - name: document
      uses: synthesis
      constraints:
        - "Write comprehensive final report"
```

### Instructions

Non-negotiable execution rules.

- **Compare Carefully**: Look for both explicit agreement and subtle alignment across models.
- **Acknowledge Contradictions**: Don't ignore conflicting recommendations; document and analyze them.
- **Weight by Consensus**: Actions recommended by multiple models carry more weight.
- **Consider Impact**: Prioritize actions based on potential impact, not just frequency of mention.
- **Be Honest About Trade-offs**: Explicitly acknowledge what you're giving up with each recommendation.
- **Reflect on Process**: Consider what worked and what didn't in your model selection and application.

### Templates

#### Input Template

```markdown
# Outcome Consolidation Request

**Problem**: [The original problem statement]

**Models Applied**:
1. [Model 1]: [Brief outcome]
2. [Model 2]: [Brief outcome]
3. [Model 3]: [Brief outcome]

**Decision Criteria**: [What matters most in the decision?]
```

#### Output Template

```markdown
# Consolidated Analysis: [Problem]

## Outcomes Summary

### Model 1: [Name]
[Key findings and recommendations]

### Model 2: [Name]
[Key findings and recommendations]

### Model 3: [Name]
[Key findings and recommendations]

## Analysis

### Common Themes
- [Theme 1]: [Which models identified this?]
- [Theme 2]: [Which models identified this?]
- [Theme 3]: [Which models identified this?]

**Interpretation**: [What do these common themes tell us?]

### Contradictions & Trade-offs
- [Contradiction 1]: [Model A says X, Model B says Y]
  - **Analysis**: [Why the difference? Which is more relevant?]
- [Contradiction 2]: [Model A says X, Model B says Y]
  - **Analysis**: [Why the difference? Which is more relevant?]

### Novel Insights
- [Insight 1]: [From Model X, unique perspective]
- [Insight 2]: [From Model Y, unique perspective]

## Consolidated Summary
[Synthesis of all insights into a coherent understanding of the problem]

## Prioritized Actions

### Priority 1 (High Impact, High Consensus)
- [Action 1]: [Why it's important, which models support it]
- [Action 2]: [Why it's important, which models support it]

### Priority 2 (Medium Impact or Moderate Consensus)
- [Action 3]: [Why it's important, which models support it]
- [Action 4]: [Why it's important, which models support it]

### Priority 3 (Lower Impact or Single Model Support)
- [Action 5]: [Why it's important, which models support it]

## Trade-offs & Risks
- [Trade-off 1]: [What you're giving up, why it's worth it]
- [Trade-off 2]: [What you're giving up, why it's worth it]
- [Risk 1]: [Potential negative consequence, mitigation strategy]
- [Risk 2]: [Potential negative consequence, mitigation strategy]

## Final Recommendations
[Clear, actionable summary of what to do]

## Reflection on Process
- **What Worked Well**: [Which models were most useful?]
- **What Was Less Helpful**: [Which models provided less value?]
- **Next Time**: [Would you use different models? Why or why not?]
```

## Design By Contract

### Preconditions

- Outcomes from all applied models are available.
- Problem statement is clear.
- Decision criteria are understood.

### Postconditions

- Common themes are identified and interpreted.
- Contradictions are acknowledged and analyzed.
- Actions are prioritized with clear rationale.
- Trade-offs are explicitly documented.

### Invariants

- All model outcomes are considered in synthesis.
- Contradictions are not ignored or minimized.
- Prioritization is based on consensus and impact, not arbitrary preference.

### Assertions

```pseudo
assert(all model outcomes are included)
assert(contradictions are identified and analyzed)
assert(actions are prioritized with rationale)
assert(trade_offs are explicitly documented)
```

### Contracts

- **Synthesis Contract**: All outcomes are considered and integrated.
- **Contradiction Contract**: Conflicting recommendations are acknowledged and analyzed.
- **Prioritization Contract**: Actions are ranked based on consensus and impact.
- **Trade-off Contract**: Trade-offs and risks are explicitly documented.
- **Reflection Contract**: Process effectiveness is evaluated for future improvement.
