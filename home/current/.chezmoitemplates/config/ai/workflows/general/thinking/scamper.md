---
workflow: "SCAMPER"
slug: "scamper"
description: "Creative thinking checklist using seven prompts: Substitute, Combine, Adapt, Modify, Put to another use, Eliminate, Reverse."
use: "When developing new products, improving processes, overcoming creative blocks, or innovating existing solutions."
role: "Creative Innovator"
triggers: ["manual"]
concurrency:
  group: "scamper"
  cancel_in_progress: false
retries:
  max: 0
  backoff_secs: 0
safety:
  dry_run: false
  confirm_dangerous_ops: false
artifacts: ["scamper-analysis.md"]
permissions: ["read"]

tools:
  - name: "ideation"
    description: "Generate ideas using SCAMPER prompts"
    inputs:
      - name: "subject"
        type: "string"
        required: true
        description: "The product, process, or service to improve"
      - name: "context"
        type: "string"
        required: false
        description: "Current challenges or desired improvements"
    outputs:
      - name: "ideas"
        type: "string"
        description: "Creative ideas generated through SCAMPER"
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

# SCAMPER

## Goal

Generate creative ideas by systematically applying seven prompts to a product, process, or service:

- **S**ubstitute: What can you replace or swap?
- **C**ombine: What can you merge or blend?
- **A**dapt: What can you adjust or modify?
- **M**odify: What can you change or enhance?
- **P**ut to another use: What new applications exist?
- **E**liminate: What can you remove or simplify?
- **R**everse: What can you flip or invert?

Success criteria: A diverse set of actionable ideas that improve or innovate the subject.

### Role

- **Creative Innovator**: Systematically explore possibilities using SCAMPER prompts.

- Generate ideas without judgment; evaluate later.
- Look for unexpected combinations and applications.

## I/O

### Context

- The product, process, or service to improve.
- Current challenges or desired improvements.
- Target audience or use cases.

#### Required Context

- **Subject**: The product, process, or service to analyze.

#### Suggested Context

- Current limitations or pain points.
- Target market or users.
- Competitive landscape.

### Inputs

Parameterization for SCAMPER ideation.

```yaml
schema:
  inputs:
    - name: subject
      type: string
      required: true
      description: "The product, process, or service to improve"
      example: "Coffee mug"
    - name: context
      type: string
      required: false
      description: "Current challenges or desired improvements"
      example: "Make it more sustainable and functional"
```

### Outputs

Creative ideas organized by SCAMPER category.

```yaml
schema:
  outputs:
    - name: substitute_ideas
      type: array<string>
      required: true
      description: "Ideas from substituting components or materials"
    - name: combine_ideas
      type: array<string>
      required: true
      description: "Ideas from combining with other products"
    - name: adapt_ideas
      type: array<string>
      required: true
      description: "Ideas from adapting from other contexts"
    - name: modify_ideas
      type: array<string>
      required: true
      description: "Ideas from changing attributes or features"
    - name: put_to_use_ideas
      type: array<string>
      required: true
      description: "Ideas from new applications or uses"
    - name: eliminate_ideas
      type: array<string>
      required: true
      description: "Ideas from removing or simplifying"
    - name: reverse_ideas
      type: array<string>
      required: true
      description: "Ideas from reversing or inverting"
    - name: top_ideas
      type: array<string>
      required: false
      description: "Most promising ideas for further development"
```

## Operation

Phased SCAMPER ideation.

1. **Define Subject**: Clearly describe the product, process, or service.
2. **Apply Substitute**: What can you replace or swap?
3. **Apply Combine**: What can you merge or blend?
4. **Apply Adapt**: What can you adjust or modify?
5. **Apply Modify**: What can you change or enhance?
6. **Apply Put to Another Use**: What new applications exist?
7. **Apply Eliminate**: What can you remove or simplify?
8. **Apply Reverse**: What can you flip or invert?
9. **Evaluate Ideas**: Which ideas are most promising?

### Tools

Declare the tools used at each step.

```yaml
manifest:
  steps:
    - name: define_subject
      uses: ideation
      constraints:
        - "Describe the subject clearly"
    - name: apply_scamper
      uses: ideation
      constraints:
        - "Generate ideas for each SCAMPER prompt"
        - "No judgment; quantity over quality at this stage"
    - name: evaluate_ideas
      uses: ideation
      constraints:
        - "Identify most promising ideas"
```

### Instructions

Non-negotiable execution rules.

- **Generate Freely**: Don't judge ideas during ideation; evaluate later.
- **Be Specific**: Each idea should be concrete and actionable.
- **Combine Prompts**: Some ideas may combine multiple SCAMPER prompts.
- **Think Radically**: Allow ideas that seem impractical; they may inspire better ones.
- **Evaluate Later**: After generating, assess feasibility and impact.

### Templates

#### Input Template

```markdown
# SCAMPER Ideation

**Subject**: [Product, process, or service to improve]

**Current State**: [How it works now]

**Desired Outcome**: [What should improve?]
```

#### Output Template

```markdown
# SCAMPER Ideas: [Subject]

## Substitute
- [Idea 1]: [What to replace and with what]
- [Idea 2]: [What to replace and with what]

## Combine
- [Idea 1]: [What to merge with what]
- [Idea 2]: [What to merge with what]

## Adapt
- [Idea 1]: [What to adapt from where]
- [Idea 2]: [What to adapt from where]

## Modify
- [Idea 1]: [What to change and how]
- [Idea 2]: [What to change and how]

## Put to Another Use
- [Idea 1]: [New application or use case]
- [Idea 2]: [New application or use case]

## Eliminate
- [Idea 1]: [What to remove or simplify]
- [Idea 2]: [What to remove or simplify]

## Reverse
- [Idea 1]: [What to flip or invert]
- [Idea 2]: [What to flip or invert]

## Top Ideas for Development
- [Idea 1]: [Why it's promising]
- [Idea 2]: [Why it's promising]
```

## Design By Contract

### Preconditions

- Subject is clearly defined.
- Context and desired outcomes are understood.

### Postconditions

- Ideas are generated for all seven SCAMPER prompts.
- Top ideas are identified for further development.

### Invariants

- Ideation is non-judgmental and generative.
- Ideas are organized by SCAMPER category.

### Assertions

```pseudo
assert(subject is clearly defined)
assert(ideas generated for all SCAMPER prompts)
assert(top_ideas are identified and promising)
```

### Contracts

- **Ideation Contract**: Ideas are generated for each SCAMPER prompt.
- **Creativity Contract**: Ideas are diverse and creative.
- **Evaluation Contract**: Top ideas are identified and justified.
