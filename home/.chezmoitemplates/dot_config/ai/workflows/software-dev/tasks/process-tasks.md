---
description: Process Tasks
---
# Task List Management

Guidelines for managing task lists in markdown files to track progress on completing a PRD

## Scope

This workflow processes tasks that were already created by `prd-to-tasks.md` workflow.

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

## AI Instructions

When working with task lists, the AI must:

1. Assume the primary reader of the task list is a **junior developer** who will implement the feature.

## Outputs

Initialize and maintain artifacts for stories already defined by `prd-to-tasks.md` workflow:

1. **PRD Dashboard (status table)** — A single overview file that tracks all stories across sequential phases and parallel sets.
2. **Per-Story Files** — One file per story with detailed scope, dependencies, and acceptance criteria.

### 1) PRD Dashboard (Markdown table)

- **Location:** `internal-docs/feature/[prd-name]/tasks/`
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
- Branch format: `feature/current/[PRD-TITLE-NO-SPACES]/story-[PP]-[III]-[STORY-TITLE-NO-SPACES]`.
- Keep dashboard in sync with per-story files after each change.

### 2) Per-Story File Template

- **Location:** `internal-docs/feature/[prd-name]/tasks/`
- **Filename:** `tasks-[prd-file-name]-[PP]-[III]-[STORY-TITLE-NO-SPACES].md`

Use the following structure for each story file:

```markdown
---
- Story ID: PP-III (e.g., 02-001)
- Phase: PP
- Parallel-safe: true/false
- Branch: feature/current/[PRD-TITLE-NO-SPACES]/story-[PP]-[III]-[STORY-TITLE-NO-SPACES]
- Status: [ ] Todo | [~] In-Progress | [x] Done | [!] Blocked
- Assignee: @username
- Dependencies: 01-001, 01-002
- Dependants: 03-001
- Modules/Areas Impacted: api/auth, db/migrations
- Files Impacted:
  - path/to/file.ext — short reason
  - another/path.ext — short reason
---

# [Story Title]
## User Story

### Role
As a <role>,

### Capability
I want <capability>,

### Value
so that <outcome/value>.

## Description

Concise scope of change, boundaries, and key decisions.

## Acceptance Criteria (Gherkin)

- Given <precondition>, When <action>, Then <result>
- Given ..., When ..., Then ...

## Priority (MoSCoW)

- Must | Should | Could | Won't (for now)

## Risks & Mitigations

- Risk: ... | Mitigation: ...

## Test Plan

- Unit: what to cover, edge cases
- Integration: flows and interfaces
- Performance: targets/limits
- Security: authz/authn, OWASP, data handling

## Observability

- Logging, metrics, traces to add/update

## Compliance

- TODO: Compliance — data retention, PII, licensing, accessibility

## Definition of Done

- [ ] Code merged
- [ ] Tests added/updated and passing
- [ ] Docs updated
- [ ] Dashboard updated (status, links)

## Workflow Tips

- Keep stories narrowly scoped to minimize merge conflicts across parallel worktrees.
- Update the dashboard table immediately when a story status changes.
- Link each story row in the dashboard to its corresponding per-story file.

## AI Instructions

When working with task lists, the AI must:

0. Do not invent the initial story list — use the stories created by the `prd-to-tasks.md` workflow.
1. Regularly update the task list file after finishing any significant work.
2. Follow the completion protocol:
   - Mark each finished **sub‑task** `[x]`.
   - Mark the **parent task** `[x]` once **all** its subtasks are `[x]`.
3. Propose newly discovered tasks and wait for user approval before adding.
4. Keep "Relevant Files" accurate and up to date.
5. Before starting work, check which sub‑task is next.
6. After implementing a sub‑task, update the file and then pause for user approval.
