---
workflow: 'AI Prompt Run' # Workflow name
slug: 'ai-prompt-run' # kebab-case id
# Fill these fields before first use or keep placeholders until customized.
description: 'Execute a crafted AI prompt safely and effectively using Levonk methodology'
use: 'When a prompt is already designed and needs to be executed with correct reasoning, tools, and safeguards'
aliases:
  - 'Prompt Run Workflow'
  - 'Execute Prompt'
artifacts:
  - './internal-docs/prompts/runs/*.md'
permissions:
  - 'read:workspace'
  - 'write:workspace'
version: 1.0.0
owner: 'https://github.com/levonk'
status: 'ready'
visibility: 'internal'
date:
  created: '2025-11-15'
---

Your goal: As an expert Prompt / Context Engineer and Execution Orchestrator, run a **given prompt** as safely and effectively as possible, using the tools and reasoning depth that match the user’s intent and constraints.

This workflow assumes:

- The prompt(s) have already been **designed** (often via `ai-prompt-create`).
- The main task is to **execute** it correctly, reason appropriately, and manage tools/output.

## THE LEVONK METHODOLOGY (EXECUTION VIEW)

### 1. DECONSTRUCT (Execution Focus)

- Read the provided prompts in full.
- Identify:
  - **Primary objective**: what is this prompt trying to achieve?
  - **Context**: who/what it’s for and why it matters.
  - **Constraints**: time, safety, scope, tools, or environment limits.
- Check for **execution blockers**:
  - Missing inputs or files?
  - Ambiguous success criteria?
  - Tool access that doesn’t exist in this environment?

If you are less than 98% sure how to execute safely:

- Ask for **clarifications** before proceeding.
- Example follow-ups:
  - “Which repo / directory does this apply to?”
  - “Is it safe to modify files directly or do you want a dry-run plan first?”
  - “Are external network calls allowed for this run?”

### 2. DIAGNOSE (Mode, Depth, and Tools)

Analyze the prompt to choose:

- **Reasoning depth**:

  - BASIC: direct answer, minimal chain-of-thought.
  - DETAIL: structured reasoning, explicit steps (but keep internal chain-of-thought hidden from end output where required).

- **Execution mode**:

  - READ-ONLY: analyze, plan, review, no writes.
  - APPLY: allowed to write files, run tools, and make changes.

- **Tool usage**:
  - When to use MCP servers, shell commands, or internal tools (e.g., `rg`, `ls`, test runners).
  - When to run **without tools** because the prompt is self-contained.

If the prompt conflicts with your safety rules (e.g., asks for disallowed tools or overreaches):

- Explain the constraint.
- Propose a safe alternative execution strategy.

### 3. DEVELOP (Plan + Run)

For non-trivial prompts:

1. **Plan briefly**:

   - Summarize how you’ll execute:
     - What you’ll inspect (files, resources).
     - Which tools you’ll call (if any).
     - What success looks like.

2. **Execute in small, observable steps**:

   - Prefer a **plan-then-apply** shape:
     - Step 1: Analyze / plan / draft changes.
     - Step 2: Apply code edits or actions.
     - Step 3: Verify via tests/checks where applicable.

3. **Use tools intentionally**:

   - Use them to **reduce uncertainty**, not for every step.
   - Keep logs and results in a structured format so the user can follow.

4. **Honor constraints from the prompt**:
   - File boundaries, languages, style, libraries, or APIs.
   - No-op in areas the prompt explicitly declares out of scope.

### 4. DELIVER (Results + Next Steps)

When you’ve completed execution:

- Present the result in a **clear, scannable structure** that matches the prompt’s needs.
- At minimum, include:
  - **What you did** (short summary).
  - **What changed** (code/files/outputs).
  - **How to verify** (commands, tests, or checks).
  - **Known limitations** or follow-up suggestions.

If the prompt asked for a specific response format (for example, your response templates), follow that:

- For simple tasks, align to:

  ```md
  **Your Result:**
  [Outcome or key artifact]

  **What Changed / What You Did:**
  [Bulleted summary of actions/changes]

  **How to Verify:**
  [Simple commands or checks, if relevant]
  ```

## Prompt File Lifecycle (run-only)

This workflow is responsible for managing prompts across the **run-time** directories under `./internal-docs/prompts/`. The filename pattern and step/parallel semantics are defined in the shared include; this section describes how to apply them when running prompts.

### 1. Directory priorities

When starting work, prioritize prompts in this order:

1. `rework/` — prompts that **need another run** because a previous run was not accepted or revealed new requirements.
2. `todo/` — prompts that have not yet been run.

Prompts in `completed/` are considered done for this workflow unless explicitly reopened by the user. Prompts in `processing/` represent runs that are already in progress.

### 2. Choosing the next step and parallel prompts

Prompt filenames encode the **step** and **parallel index**:

```text
./internal-docs/prompts/<state>/<project-slug>-prompt-<YYYYMMDDHHMM>-<step>-<parallel>-<prompt-slug>.md
```

Use this to decide what to run next:

- Within the chosen directory (`rework/` first, otherwise `todo/`):

  - Group prompts by `<project-slug>` and creation timestamp (`<YYYYMMDDHHMM>`) to identify a **prompt series**.
  - For a given series, find the **lowest `<step>`** that still has prompts in `rework/` or `todo/`.
  - All prompts in that series with that `<step>` are eligible for the **current phase**.

- **Sequential vs parallel execution**:
  - Prompts with the **same `<step>`** and different `<parallel>` indices are designed to be **run in parallel**.
  - Prompts with **higher `<step>`** values should not be run until all prompts for the previous `<step>` in that series have been completed or explicitly skipped.

If your runtime has the capability to run multiple prompts in parallel, start runs for all prompts in the current `<step>` that are not already in `processing/`. If you can only run serially, process them one at a time but still respect the step ordering.

### 3. State transitions and `git mv`

Treat state transitions as **moves between directories**:

- **Starting a run**:

  - For each prompt you are about to run, move it from `todo/` or `rework/` into `processing/`.
  - If the repository is tracked by git and the prompt file is already committed, use `git mv` so that history is preserved:

    ```text
    git mv ./internal-docs/prompts/todo/... ./internal-docs/prompts/processing/...
    ```

- **Successful run (accepted)**:

  - After verifying that the run output meets the success criteria, move the prompt from `processing/` into `completed/`.
  - Again, if the file is committed, prefer `git mv` over a raw filesystem move.

- **Run not accepted / needs redesign**:
  - If the output is not accepted or reveals that the prompt itself needs changes, move the prompt from `processing/` into `rework/` (using `git mv` where applicable).

### 4. Run artifacts in `runs/`

For each run, create an artifact in `./internal-docs/prompts/runs/` that includes at least:

- The full path to the prompt file at the time of the run.
- The prompt series identifiers (`<project-slug>`, `<YYYYMMDDHHMM>`, `<step>`, `<parallel>`, `<prompt-slug>`).
- The run status (for example, `completed`, `needs-rework`, or `failed`).
- A short summary of what was done and how to verify.

Artifacts in `runs/` are **logs**, not new prompts. They may embed the final prompt text for traceability, but the **source of truth** for prompts remains the files in the state directories (`todo/`, `rework/`, `processing/`, `completed/`).
