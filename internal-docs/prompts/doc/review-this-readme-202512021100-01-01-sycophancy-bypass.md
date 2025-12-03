---
template: 'AI Prompt Create README'
slug: 'ai-prompt-create-readme'
description: 'Design rationale for the Sycophancy Bypass review prompt'
use: 'When understanding why we lie to the LLM to get better feedback'
aliases:
  - 'Sycophancy Bypass README'
version: 1.0.0
owner: 'https://github.com/levonk'
status: 'ready'
date:
  created: '2025-12-02'
  updated: '2025-12-02'
tags:
  - 'ai/prompt/review'
  - 'technique/sycophancy-bypass'
---

# Prompt Design README

## Prompt Series

- **Project slug:** `review`
- **Prompt ID:** `202512021100-01-01-sycophancy-bypass`
- **Location:** `./internal-docs/prompts/todo/review-prompt-202512021100-01-01-sycophancy-bypass.md`

## Goal

- **Objective:** Obtain ruthless, unbiased critique of content (code, text, architecture) from an LLM.
- **Problem:** LLMs are trained to be helpful, harmless, and honest (often interpreted as "polite"). This "sycophancy" leads them to gloss over flaws to avoid offending the user.
- **Solution:** Leverage the "Lying to LLMs" technique identified by Sean Goedecke to frame the content as belonging to a third party, explicitly soliciting critique.

## Design Decisions

### 1. The "Lie" Context
We explicitly instruct the model that the user *did not* write the content. We assign the authorship to a "persona" (e.g., External Vendor, Junior Dev) that invites scrutiny. This breaks the "don't be mean to the user" safety rail.

### 2. Two-Phase Output
- **Phase 1 (The Tear-down):** We ask for a blunt list of flaws. We explicitly forbid "sandwich feedback".
- **Phase 2 (The Synthesis):** We ask the model to filter its own critique for *validity* and *importance*, converting the raw feedback into actionable advice. This separates "being mean" from "being useful".

### 3. Variable Injection
- `{{SOURCE_PERSONA}}`: Allows tuning the type of critique. (e.g., "Competitor" -> Logical holes; "Vendor" -> Cost/Upsell risk).

## References

- **Source Article:** [Lying to LLMs](https://www.seangoedecke.com/lying-to-llms/) by Sean Goedecke.
- **Key Insight:** "If you want the model to tell you the truth, you often have to lie to it about who wrote the text."

## Future Adjustments

- Could create specialized variants for Code Review vs. Copywriting.
- Could add a "Persona Library" for different critique angles (Security Auditor, V.C. Investor, etc.).
