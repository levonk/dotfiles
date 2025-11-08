---
workflow: "Choose Thinking Models for a Problem"
slug: "choose-thinking-models"
description: "Guide for selecting appropriate mental models from your index to solve a specific problem or make a decision."
use: "When facing a complex problem and need to determine which thinking models are most relevant and useful for analysis."
role: "Model Selector & Strategist"
triggers: ["manual"]
concurrency:
  group: "choose-thinking-models"
  cancel_in_progress: false
retries:
  max: 0
  backoff_secs: 0
safety:
  dry_run: false
  confirm_dangerous_ops: false
artifacts: ["model-selection-report.md"]
permissions: ["read"]

tools:
  - name: "selection"
    description: "Select and evaluate thinking models for a problem"
    inputs:
      - name: "problem"
        type: "string"
        required: true
        description: "The problem or decision to analyze"
      - name: "context"
        type: "string"
        required: false
        description: "Constraints, stakeholders, and background information"
    outputs:
      - name: "selection"
        type: "string"
        description: "Selected models with rationale and application plan"
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

# Choose Thinking Models for a Problem

## Goal

Systematically select the most appropriate mental models from your index to analyze a specific problem or decision. This workflow:
- Ensures you choose models that fit your problem's nature
- Prevents random or ineffective model selection
- Creates a clear rationale for why each model is useful
- Prepares outcomes for later consolidation

Success criteria: 1-3 well-justified mental models selected and ready for application.

### Role

- **Model Selector & Strategist**: Match problems to appropriate models based on problem nature and keywords.
- Understand the problem deeply before selecting models.
- Choose models that provide complementary perspectives.

## I/O

### Context

- The specific problem or decision to analyze.
- Constraints, stakeholders, and background information.
- Available mental models from your index.

#### Required Context

- **Problem**: The issue or decision you're trying to address.

#### Suggested Context

- Constraints and limitations.
- Key stakeholders involved.
- Time horizon for the decision.
- Previous attempts or approaches.

### Inputs

Parameterization for model selection.

```yaml
schema:
  inputs:
    - name: problem
      type: string
      required: true
      description: "The problem or decision to analyze"
      example: "Low team productivity and high burnout"
    - name: context
      type: string
      required: false
      description: "Constraints, stakeholders, and background information"
      example: "Small team, high workload, remote work, competing priorities"
```

### Outputs

Model selection with clear rationale.

```yaml
schema:
  outputs:
    - name: problem_statement
      type: string
      required: true
      description: "Refined problem statement"
    - name: problem_category
      type: array<string>
      required: true
      description: "Categories from the Mental Model Index that fit this problem"
    - name: keywords
      type: array<string>
      required: true
      description: "3-5 keywords describing the problem's core elements"
    - name: problem_type
      type: string
      required: true
      description: "Type of problem (decision with uncertainty, complex system, creative challenge, risk assessment, etc.)"
    - name: candidate_models
      type: array<string>
      required: true
      description: "Models considered from the index"
    - name: selected_models
      type: array<string>
      required: true
      description: "1-3 models chosen with rationale"
    - name: application_plan
      type: array<string>
      required: false
      description: "How to apply each selected model"
```

## Operation

Phased model selection process.

1. **Define Problem Clearly**: State the problem precisely with context.
2. **Identify Problem's Nature**: Determine category, keywords, and type.
3. **Explore Possible Models**: Review models in relevant categories.
4. **Evaluate Model Fit**: Assess how well each model matches the problem.
5. **Select Models**: Choose 1-3 models with clear rationale.
6. **Plan Application**: Outline how to apply each model.

### Tools

Declare the tools used at each step.

```yaml
manifest:
  steps:
    - name: define_problem
      uses: selection
      constraints:
        - "Be precise and specific"
    - name: identify_nature
      uses: selection
      constraints:
        - "Identify category, keywords, and problem type"
    - name: explore_models
      uses: selection
      constraints:
        - "Review all models in relevant categories"
    - name: evaluate_fit
      uses: selection
      constraints:
        - "Assess how well each model matches the problem"
    - name: select_models
      uses: selection
      constraints:
        - "Choose 1-3 models; write clear rationale"
    - name: plan_application
      uses: selection
      constraints:
        - "Outline how to apply each model"
```

### Instructions

Non-negotiable execution rules.

- **Understand the Problem First**: Don't rush to model selection; deeply understand the problem.
- **Match Keywords**: Look for models whose "Best Use Cases" align with your problem's keywords.
- **Consider Complementarity**: Choose models that provide different perspectives, not just similar ones.
- **Write Clear Rationale**: For each model, explain *why* it's relevant to this specific problem.
- **Plan Application**: Before applying, outline how you'll use each model.

### Templates

#### Input Template

```markdown
# Model Selection Request

**Problem**: [Briefly describe the issue or decision]

**Context**: [Constraints, stakeholders, background]

**What I hope to achieve**: [Desired outcome or insight]
```

#### Output Template

```markdown
# Model Selection Report: [Problem]

## Problem Statement
[Refined, precise statement of the problem]

## Problem Analysis

**Category**: [Which category(ies) from the Mental Model Index?]

**Keywords**: [3-5 keywords describing the problem]

**Problem Type**: [Decision with uncertainty, complex system, creative challenge, risk assessment, etc.]

## Candidate Models Considered
- [Model 1]: [Why it was considered]
- [Model 2]: [Why it was considered]
- [Model 3]: [Why it was considered]

## Selected Models (1-3)

### Model 1: [Name]
**Rationale**: [Why this model is relevant to this specific problem]

**How to apply**: [Specific steps or approach]

**Expected insights**: [What you hope to learn from this model]

### Model 2: [Name]
**Rationale**: [Why this model is relevant to this specific problem]

**How to apply**: [Specific steps or approach]

**Expected insights**: [What you hope to learn from this model]

## Application Plan
1. [Apply Model 1]
2. [Apply Model 2]
3. [Consolidate outcomes using the Meta-Workflow]

## Notes
[Any additional considerations or constraints]
```

## Design By Contract

### Preconditions

- Problem is clearly stated and specific.
- Context is understood.
- Mental Model Index is available for reference.

### Postconditions

- 1-3 models are selected with clear rationale.
- Application plan is documented.
- Models provide complementary perspectives.

### Invariants

- Model selection is based on problem nature, not arbitrary preference.
- Rationale is specific to this problem, not generic.
- Selected models are distinct and complementary.

### Assertions

```pseudo
assert(problem is clearly stated)
assert(1 <= selected_models.length <= 3)
assert(each model has specific rationale)
assert(models provide different perspectives)
```

### Contracts

- **Selection Contract**: Models are chosen based on problem analysis, not preference.
- **Rationale Contract**: Each model has a specific, problem-focused rationale.
- **Complementarity Contract**: Selected models provide different lenses on the problem.
