---
workflow: "Circle of Competence"
slug: "circle-of-competence"
description: "Define and operate within your boundaries of knowledge, expertise, and skill."
use: "When making decisions, seeking advice, or evaluating whether you should tackle a problem yourself or delegate to an expert."
role: "Self-Assessor & Strategist"
triggers: ["manual"]
concurrency:
  group: "circle-of-competence"
  cancel_in_progress: false
retries:
  max: 0
  backoff_secs: 0
safety:
  dry_run: false
  confirm_dangerous_ops: false
artifacts: ["competence-map.md"]
permissions: ["read"]

tools:
  - name: "assessment"
    description: "Evaluate knowledge boundaries and expertise"
    inputs:
      - name: "domain"
        type: "string"
        required: true
        description: "The domain or skill area to assess"
      - name: "context"
        type: "string"
        required: false
        description: "Current situation or decision requiring assessment"
    outputs:
      - name: "assessment"
        type: "string"
        description: "Clear mapping of competence boundaries"
version: 1.0.0
owner: "user"
status: "ready"
visibility: "internal"
compliance: []
runtime:
  duration:
    min: "3m"
    max: "10m"
    avg: "5m"
  terminate: "manual"
date:
  created: "2025-10-25"
  updated: "2025-10-25"
---

# Circle of Competence

## Goal

Define the boundaries of your knowledge, expertise, and skill in a specific domain. The goal is not to maximize the size of your circle, but to **clearly understand its edges** so you can:

- Make confident decisions within your competence
- Know when to seek expert advice
- Avoid overconfidence in unfamiliar territory
- Build expertise strategically

Success criteria: A clear, honest map of what you know well, what you know partially, and what you don't know.

### Role

- **Self-Assessor & Strategist**: Honestly evaluate your expertise and identify gaps.
- Distinguish between "I know this" and "I've heard about this."
- Recognize that competence is domain-specific and evolves over time.

## I/O

### Context

- The domain or skill area under assessment.
- Current decisions or situations that require competence evaluation.
- Your background and experience in related areas.

#### Required Context

- **Domain**: The specific area of knowledge or skill to assess.

#### Suggested Context

- Recent decisions or situations where you felt confident or uncertain.
- Feedback from others about your expertise.
- Gaps you've noticed in your knowledge.

### Inputs

Parameterization for the competence assessment.

```yaml
schema:
  inputs:
    - name: domain
      type: string
      required: true
      description: "The domain or skill area to assess"
      example: "Machine Learning for Product Recommendations"
    - name: context
      type: string
      required: false
      description: "Current situation or decision requiring assessment"
      example: "Evaluating whether to build an ML recommendation engine in-house"
```

### Outputs

Competence map with clear boundaries and recommendations.

```yaml
schema:
  outputs:
    - name: inner_circle
      type: array<string>
      required: true
      description: "Areas of genuine expertise and confidence"
    - name: middle_circle
      type: array<string>
      required: true
      description: "Areas of partial knowledge or developing expertise"
    - name: outer_circle
      type: array<string>
      required: true
      description: "Areas outside your competence; seek expert advice"
    - name: recommendations
      type: array<string>
      required: false
      description: "Suggested actions based on competence assessment"
```

## Operation

Phased assessment of knowledge boundaries.

1. **Define Domain**: Clarify the specific domain and its sub-areas.
2. **Inner Circle**: Identify areas where you have deep, proven expertise.
3. **Middle Circle**: Identify areas where you have partial knowledge or are developing expertise.
4. **Outer Circle**: Identify areas where you lack competence and should seek experts.
5. **Assess Confidence**: Rate your confidence level in each circle.
6. **Identify Gaps**: Recognize critical gaps that could lead to poor decisions.
7. **Recommend Actions**: Suggest whether to build expertise, seek advice, or delegate.

### Tools

Declare the tools used at each step.

```yaml
manifest:
  steps:
    - name: define_domain
      uses: assessment
      constraints:
        - "Be specific; avoid vague domains"
    - name: inner_circle
      uses: assessment
      constraints:
        - "Only include areas of proven, deep expertise"
    - name: middle_circle
      uses: assessment
      constraints:
        - "Distinguish between 'I know some' and 'I know well'"
    - name: outer_circle
      uses: assessment
      constraints:
        - "Be honest about gaps; don't overestimate knowledge"
    - name: recommendations
      uses: assessment
      constraints:
        - "Suggest concrete next steps"
```

### Instructions

Non-negotiable execution rules.

- **Intellectual Honesty**: Avoid overconfidence. If you're uncertain, it belongs in the middle or outer circle.
- **Specificity**: Define sub-domains clearly. "Technology" is too broad; "Kubernetes" is better.
- **Proven Expertise**: Inner circle should reflect demonstrated competence, not just familiarity.
- **Recognize Evolution**: Your circles change over time as you learn and experience.
- **Seek Feedback**: Ask trusted colleagues if your self-assessment aligns with their perception.

### Templates

#### Input Template

```markdown
# Circle of Competence Assessment

**Domain**: [Specific domain or skill area]

**Context**: [Current decision or situation]

**Background**: [Your relevant experience]
```

#### Output Template

```markdown
# Competence Map: [Domain]

## Inner Circle (Deep Expertise)
- [Area 1]: [Why you're confident]
- [Area 2]: [Why you're confident]

## Middle Circle (Partial Knowledge)
- [Area 1]: [What you know and don't know]
- [Area 2]: [What you know and don't know]

## Outer Circle (Outside Competence)
- [Area 1]: [Why you lack expertise]
- [Area 2]: [Why you lack expertise]

## Confidence Assessment
- Inner Circle Confidence: [%]
- Middle Circle Confidence: [%]
- Outer Circle Confidence: [%]

## Recommendations
- [Action 1]: [Build expertise, seek advice, or delegate]
- [Action 2]: [Build expertise, seek advice, or delegate]

## Critical Gaps
- [Gap 1]: [Why it matters and how to address it]
```

## Design By Contract

### Preconditions

- Domain is clearly defined and specific.
- Self-assessment is honest and evidence-based.

### Postconditions

- Competence map clearly distinguishes inner, middle, and outer circles.
- Recommendations are actionable and aligned with competence boundaries.

### Invariants

- Assessment remains objective and avoids overconfidence.
- Outer circle is treated with humility; experts are consulted.

### Assertions

```pseudo
assert(domain is specific and well-defined)
assert(inner_circle reflects proven expertise)
assert(outer_circle is not empty; no one is expert in everything)
```

### Contracts

- **Assessment Contract**: Each circle is clearly defined with specific examples.
- **Honesty Contract**: Self-assessment is evidence-based and acknowledges gaps.
- **Action Contract**: Recommendations align with competence boundaries.
