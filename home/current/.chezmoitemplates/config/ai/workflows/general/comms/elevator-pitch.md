---
template: "Elevator Pitch + Follow-Up Guidance"
slug: "elevator-pitch"
# Fill these fields before first use.
description: "Interactive AI-guided workflow to craft a crisp elevator pitch and a concise follow-up explanation with audience-fit and credibility."
use: "Use when drafting a short, compelling elevator pitch and a brief follow-up that explains how/why it works for the intended audience."
role: "Scaffold/Renderer"
engine: "go-template"
outputs_to: [
  "~/drafts/pitches/",
  "~/presentations/",
  "~/outreach/"
]
variables:
  schema:
    - name: audience
      type: string
      required: true
      default: "general"
      description: "Intended listener; e.g., enterprise CTO, startup founder, recruiter, general consumer."
    - name: audience_specificity
      type: string
      required: true
      default: "broad"
      description: "Targeting level: broad | segment | persona-specific."
    - name: industry
      type: string
      required: false
      default: ""
      description: "Industry or domain; e.g., fintech, healthcare, devtools."
    - name: listener_context
      type: string
      required: false
      default: "cold-intro"
      description: "Setting; e.g., conference, sales call, interview, investor meeting, networking."
    - name: problem
      type: string
      required: true
      default: ""
      description: "Primary pain the audience feels in their words."
    - name: tangible_outcome
      type: string
      required: true
      default: ""
      description: "Concrete outcome/benefit delivered (time saved, revenue, risk reduced)."
    - name: mechanism
      type: string
      required: true
      default: ""
      description: "How it works at a high level (no buzzword salad)."
    - name: differentiation
      type: string
      required: true
      default: ""
      description: "Why this is meaningfully different/better vs status quo or alternatives."
    - name: credibility_proof
      type: string
      required: false
      default: ""
      description: "Optional proof point (metric, case, logo-safe reference, demo evidence)."
    - name: call_to_action
      type: string
      required: true
      default: "schedule a 10-min chat"
      description: "Clear next step appropriate to the context."
    - name: tone
      type: string
      required: true
      default: "confident, clear, respectful"
      description: "Style; e.g., formal, casual, product-forward, outcome-first, elusive-not-lying."
    - name: length_seconds
      type: number
      required: true
      default: 20
      description: "Target delivery time in seconds (15–30 typical)."
    - name: vocabulary_level
      type: string
      required: false
      default: "plain-language"
      description: "Jargon level; e.g., plain-language, moderate technical, expert-only."
    - name: constraints
      type: string
      required: false
      default: "no NDAs violated; no private data; no unverified claims"
      description: "Hard constraints; avoid false precision or hype."
    - name: follow_up_depth
      type: string
      required: true
      default: "one-paragraph explanation"
      description: "Length and depth of the follow-up explanation."
    - name: delivery_format
      type: string
      required: false
      default: "spoken-first"
      description: "Primary channel; e.g., spoken-first, email, LinkedIn DM, slide one-liner."
partials: []
conflicts:
  strategy: "merge"
  backup: true
validation: ["lint:markdown", "length:<=30s", "cta:present", "no-claims-without-proof"]
tools:
  - name: "speech-timer"
    description: "Verifies pitch can be spoken within target seconds at ~130–150 wpm."
  - name: "readability"
    description: "Checks for plain-language and removes filler and buzzwords."
version: 1.0.0
owner: "levonk"
status: "ready"
visibility: "internal"
compliance: ["no-hardcoded-claims", "privacy-safe"]
runtime:
  duration:
    min: "5m"
    max: "20m"
    avg: "10m"
  terminate: "Stop if critical inputs (problem, outcome, CTA) remain undefined after two iterations."
date:
  created: "{{ now | default "" }}"
  updated: ""
---

# Elevator Pitch + Follow-Up

## Goal

- Produce a crisp, 15–30 second elevator pitch tailored to a specific audience; include a short follow-up paragraph that explains how it works and why it matters without hype or dishonesty.

### Role

- Provide a structured, interactive scaffold that elicits audience, pain, mechanism, differentiation, proof, and CTA; ensure the pitch is truthful, targeted, and time-bounded.

## i/o

### Context

- Pitches must be audience-fit, time-bounded, and verifiable. Avoid hard claims without proof. Prefer outcomes over features; clarity over cleverness.

#### Required Context

- audience, problem, tangible_outcome, mechanism, differentiation, call_to_action, tone, length_seconds, follow_up_depth

#### Suggested Context

- industry, listener_context, credibility_proof, vocabulary_level, delivery_format, constraints

### Inputs

- Variables gathered interactively via the question script below.

```yaml
schema:
  inputs:
    - name: vars
      type: object
      required: true
      example:
        audience: enterprise CTO
        industry: devtools
        listener_context: conference hallway
        problem: 'Engineering teams waste hours/week on flaky CI.'
        tangible_outcome: 'cut CI failures by 40% and speed merges 2x'
        mechanism: 'we add a statistical flake detector and rerun orchestration layer on top of your existing CI'
        differentiation: 'works with any CI, deploys in a day, no vendor lock-in'
        credibility_proof: 'saved 18k engineer-hours across 12 teams last quarter'
        call_to_action: '10-min test-drive on your pipeline'
        tone: confident, clear, respectful
        length_seconds: 20
        vocabulary_level: plain-language
        constraints: 'no unverified claims'
        follow_up_depth: one-paragraph explanation
        delivery_format: spoken-first
```

### Outputs

- One elevator pitch (<= target seconds) and one follow-up explanation paragraph aligned to the audience and context.

```yaml
schema:
  outputs:
    - name: files
      type: array<{path: string, mode?: string}>
      required: true
      acceptance:
        - "Pitch speaks within target seconds at 130–150 wpm"
        - "CTA is explicit and friction-light"
        - "No unverified claims; any numbers cite provenance or are framed as ranges/estimates"
        - "Follow-up explains mechanism and differentiation in plain language"
```

## Operation

1. Initialize: validate required inputs; default optional ones.
2. Plan: estimate speaking time; strip filler and buzzwords.
3. Apply: generate the pitch; then create the follow-up explanation.
4. Verify: run readability and time checks; assert CTA present; ensure honesty.
5. Deliver: output final pitch and follow-up; include a 1-line rationale.

### Tools

- speech-timer; readability checker; basic linting and honesty checks.

### Instructions

- Keep it outcome-first; avoid feature-dumps. Use the audience’s words for the problem. Prefer a single clear CTA. If proof is weak, frame carefully (e.g., "early results suggest...").

### Templates

#### Interactive Question Script (for AI-guided collection)

```markdown
- Is this for a specific audience or general consumption?
  - If specific: Who exactly (role, seniority, industry)?
  - If general: Who is the most likely listener and what do they value?
- What problem does the listener already admit they have? Use their words.
- What tangible outcome do they want (time, money, risk, quality)?
- How do you deliver that outcome at a high level, without jargon?
- Why is this approach meaningfully different or better than their status quo?
- Do you have light-proof (metric, case, demo) you can safely reference?
- What tone fits the setting (formal, casual, confident, elusive-not-lying)?
- Where will this be delivered (spoken, email, DM, slide)? Target length in seconds?
- What’s the lowest-friction next step (CTA) for this context?
- Any constraints (no NDAs; avoid names; cautious phrasing for early data)?
```

#### Pitch Shape Hints

```markdown
- Open with the listener’s problem in their language.
- Promise a tangible outcome; immediately anchor the value.
- Name the mechanism just enough to be credible, not technical.
- Add a light proof/credibility line if safe.
- Close with a single, easy next step (CTA).
```

#### Output Template

{{ template "dot_config/ai/templates/general/comms/elevator-pitch-template.md" . }}

<!-- elevator-pitch.md (rendered) -->

# Elevator Pitch

<one to three sentences; ~20 seconds when spoken>

## Follow-Up (How it works and why it matters)

<one short paragraph explaining mechanism, differentiation, and fit>

## Design By Contract

### Preconditions

- All required inputs present; delivery time target set; CTA defined; constraints honored.

### Postconditions

- Pitch and follow-up produced; readable; within time target; truthful and audience-fit.

### Invariants

- No unverified claims; no hidden assumptions; CTA always present.

### Assertions

- Assert pitch estimated speaking time <= length_seconds.
- Assert CTA present and specific.
- Assert follow-up explains mechanism and differentiation plainly.

```pseudo
assert(time_s(pitch) <= length_seconds, "Pitch exceeds time budget")
assert(has_cta(pitch), "CTA missing")
assert(explains_mechanism(follow_up), "Follow-up lacks mechanism explanation")
```

### Contracts

- Render Contracts: engine, variables, includes.
- File Contracts: conflict strategy, permissions, and backups.
