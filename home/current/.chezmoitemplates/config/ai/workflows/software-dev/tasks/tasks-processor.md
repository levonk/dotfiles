---
description: Process Tasks
---
# Task List Management

Guidelines for managing task lists in markdown files to track progress on completing a PRD

## Scope

This workflow processes tasks that were already created by `tasks-from-prd.md` (PRD-to-tasks) workflow.

- If a missing task is discovered, propose it explicitly and pause for user approval before adding.

## Task Implementation

- **One sub-task at a time:** Do **NOT** start the next sub‑task until you ask the user for permission and they say "yes" or "y"
- **Work protocol:**
  1. When you start a **sub‑task**, immediately mark it, and its parent task, as in-progress by changing `[ ]` to `[~]`.
  2. When you finish a **sub‑task**, immediately mark it as completed by changing `[ ]` to `[x]`.
  3. After finishing a **sub-task**, run type checks and linting.
  4. If **all** subtasks underneath a parent task are now `[x]`, follow this sequence:
  - **First**: Run the full test suite (`pytest`, `bun test`, `bin/rails test`, etc.)
  - **Only if all tests pass**: Stage changes (`git add .`)
  - **Clean up**: Remove any temporary files and temporary code before committing
  - **Commit**: Use a descriptive commit message that:
    - Uses scoped conventional commit format (`feat(moduleA):`, `fix(moduleB):`, `refactor(moduleC):`, etc.)
    - Summarizes what was accomplished in the parent task
    - Lists key changes and additions
    - References the task number and PRD context
    - **Formats the message as a single-line command using `-m` flags**, e.g.:

        ```bash
        git commit -m "feat(moduleA): add payment validation logic" -m "- Validates card type and expiry" -m "- Adds unit tests for edge cases" -m "Related to 02-001 in PRD user-handling"
        ```

  3. Once all the subtasks are marked completed and changes have been committed, mark the **parent task** as completed.
- Stop after each sub‑task and wait for the user's go‑ahead.

## Task List Maintenance

1. **Update the task list as you work:**
   - Mark tasks and subtasks as in-progress (`[~]`) per the protocol above.
   - Mark tasks and subtasks as completed (`[x]`) per the protocol above.
   - Add new tasks as they emerge (after approval).

2. **Maintain the "Relevant Files" section:**
   - List every file created or modified.
   - Give each file a one‑line description of its purpose.

## AI Instructions (Per-Story Files)

When working with task lists, the AI must:

1. Assume the primary reader of the task list is a **junior developer** who will implement the feature.

## Outputs

Initialize and maintain artifacts for stories already defined by `tasks-from-prd.md` workflow:

1. **PRD Dashboard (status table)** — A single overview file that tracks all stories across sequential phases and parallel sets.
2. **Per-Story Files** — One file per story with detailed scope, dependencies, and acceptance criteria.

### 1) PRD Dashboard (Markdown table)

- **Location:** `internal-docs/feature/[PRD-NAME-KEBAB-CASE]/tasks/`
- **Filename:** `overview.md`
- **Purpose:** Central status hub for all stories, optimized for parallel execution tracking.

Recommended table structure:

```markdown
| Story ID | Title | Phase | Status | Assignee | Parallel-safe | Dependencies | Dependants | Modules | Branch |
|---|---|---:|---|---|---|---|---|---|---|
| 01-001 | Groundwork: Schema | 01 | [x] Done | @dev1 | true | — | 02-001 | db, migrations | feature/current/[PRD]/story-01-001-schema |
| 01-002 | CI/CD setup | 01 | [x] Done | @dev2 | true | — | 02-002 | ci | feature/current/[PRD]/story-01-002-cicd |
| 02-001 | API: Signup | 02 | [ ] Todo | @dev3 | true | 01-001 | 03-001 | api, auth | feature/current/[PRD]/story-02-001-signup-api |
```

Status values:

- `[ ] Todo`, `[~] In-Progress`, `[x] Done`, `[!] Blocked`

Notes:

- Use Story ID format `PP-III` (phase two digits, parallel index three digits).
- Branch format: `feature/current/[PRD-NAME-KEBAB-CASE]/story-[PP]-[III]-[STORY-NAME-KEBAB-CASE]`.
- Keep dashboard in sync with per-story files after each change.

## Shared Task Definitions

{{ includeTemplate "config/ai/workflows/software-dev/tasks/tasks.md" . }}

### 2) Per-Story File Template

- **Location:** `internal-docs/feature/[PRD-NAME-KEBAB-CASE]/tasks/`
- **Filename:** `tasks-[PRD-NAME-KEBAB-CASE]-[PP]-[III]-[STORY-NAME-KEBAB-CASE].md`

Use the following structure for each story file (YAML front matter + markdown sections):

```markdown
---
story_id: "PP-III"            # e.g., "01-001"
story_title: "<story title>"
story_name: "<STORY-NAME-KEBAB-CASE>"
prd_name: "<PRD-NAME-KEBAB-CASE>"  # e.g., user-handling
prd_file: "internal-docs/feature/<PRD-NAME-KEBAB-CASE>/prd.md"
phase: 1                      # 2-digit sequential phase as integer
parallel_id: 1                # 3-digit parallel index as integer
branch: "feature/current/<PRD-NAME-KEBAB-CASE>/story-PP-III-<STORY-NAME-KEBAB-CASE>"
status: "todo"               # todo | in_progress | blocked | done | archive
assignee: ""
reviewer: ""
dependencies: ["01-001"]     # list of story_ids
parallel_safe: true
modules: ["module-a"]
priority: "MUST"             # MUST | SHOULD | COULD | WONT
risk_level: "medium"          # low | medium | high
tags: ["feat", "backend"]
due: "YYYY-MM-DD"
create-date: "YYYY-MM-DD"
update-date: "YYYY-MM-DD"
---
## Summary

One-paragraph description of the story, intent, and scope boundaries.

## Sub-Tasks

- [ ] Task 1 — scope and target files
- [ ] Task 2 — scope and target files

Status conventions: mark in-progress with `[~]`, done with `[x]`, blocked with `[!]`.

## Relevant Files

- `path/to/file.ext` — why relevant
- `another/path.ext` — why relevant

## Acceptance Criteria (Gherkin)

- Given `precondition`, When `action`, Then `result`
- Given ..., When ..., Then ...
```

## AI Instructions

When working with task lists, the AI must:

0. Do not invent the initial story list — use the stories created by the `tasks-from-prd.md` workflow.
1. Regularly update the task list file after finishing any significant work.
2. Follow the completion protocol:
   - Mark each finished **sub‑task** `[x]`.
   - Mark the **parent task** `[x]` once **all** its subtasks are `[x]`.
3. Propose newly discovered tasks and wait for user approval before adding.
4. Keep "Relevant Files" accurate and up to date.
5. Before starting work, check which sub‑task is next.
6. After implementing a sub‑task, update the file and then pause for user approval.
