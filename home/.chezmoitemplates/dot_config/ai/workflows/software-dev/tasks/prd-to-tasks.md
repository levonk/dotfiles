# Rule: Generating a Task List from a PRD

## Goal

To guide an AI assistant in creating a detailed, step-by-step task list in Markdown format based on an existing Product Requirements Document (PRD). The task list should guide a developer through implementation.

## Output

- **Format:** Markdown (`.md`)
- **Location:** `internal-docs/feature/[PRD-NAME-KEBAB-CASE]/tasks/`
- **Filename:** `tasks-[PRD-NAME-KEBAB-CASE]-[2-DIGIT-STORY-PARALLEL-PHASE]-[3-DIGIT-STORY-PARALLEL-ID]-[STORY-NAME-KEBAB-CASE].md` (e.g., `tasks-prd-user-handling-01-001-user-tables.md`, `tasks-prd-user-handling-02-001-user-signup-api.md`, `tasks-prd-user-handling-02-002-user-signup-mock-service.md`, etc.)
- See "Per-Story File Template (with YAML front matter)" for required metadata and body structure.

## Process

1. **Receive PRD Reference:** The user points the AI to a specific PRD file. If you didn't get this you must ask for it.
2. **Analyze PRD:** The AI reads and analyzes the functional requirements, user stories, and other sections of the specified PRD.
3. **Phase 1: Generate Parallel Story Sets:** Based on the PRD analysis, propose sequential phases. Within each phase, define parallel stories that can be developed simultaneously. Organize stories for **PARALLEL** execution using Git worktrees. Present only the high-level story list first (no sub-tasks yet). Inform the user: "I have generated the high-level tasks based on the PRD. Ready to generate the sub-tasks? Respond with 'Go' to proceed."
4. **Wait for Confirmation:** Pause and wait for the user to respond with "Go", "Ok", "Yes", or similar.
5. **Phase 2: Generate Sub-Tasks:** Once confirmed, for each story create smaller, actionable sub-tasks. Ensure sub-tasks logically follow from dependencies and minimize merge conflicts by scoping changes.
6. **Identify Relevant Files:** Based on the tasks and PRD, identify potential files that will need to be created or modified. List these under the `Relevant Files` section, including corresponding test files if applicable.
7. **Generate Final Output:** Combine the parent tasks, sub-tasks, relevant files, and notes into the final Markdown structure.
8. **Save Task List:** Save each story document to `internal-docs/feature/[PRD-NAME-KEBAB-CASE]/tasks/` using the filename `tasks-[PRD-NAME-KEBAB-CASE]-[2-DIGIT-STORY-PARALLEL-PHASE]-[3-DIGIT-STORY-PARALLEL-ID]-[STORY-NAME-KEBAB-CASE].md`.

## Numbering Scheme and Branch Naming

- **Use this numbering scheme:**
  - **Parallel stories**: Can be developed simultaneously within the same sequential phase.
  - **Sequential phases**: Phases must be completed in order; each phase contains a set of parallel stories.
- **For each story, include:**
  - **Story ID**: `PP-III` where `PP` is 2-digit phase, `III` is 3-digit parallel index (e.g., `01-001`).
  - **Worktree branch name**: `feature/current/[PRD-NAME-KEBAB-CASE]/story-[PP]-[III]-[STORY-NAME-KEBAB-CASE]`.
  - **Dependencies**: Prior stories (e.g., `01-001, 01-002`).
  - **Parallel safe**: `true/false`.
  - **Modules/areas impacted**: Call out directories or services to minimize conflicts.

### Example Structure

```markdown
## Parallel Development Set for Sequential Phase 1
- Story 01-001 | [Story Title] | Branch: feature/current/[PRD-NAME-KEBAB-CASE]/story-01-001-[STORY-NAME-KEBAB-CASE] | Dependencies: None | Parallel-safe: true | Modules: [module-a]
- Story 01-002 | [Story Title] | Branch: feature/current/[PRD-NAME-KEBAB-CASE]/story-01-002-[STORY-NAME-KEBAB-CASE] | Dependencies: None | Parallel-safe: true | Modules: [module-b]
- Story 01-003 | [Story Title] | Branch: feature/current/[PRD-NAME-KEBAB-CASE]/story-01-003-[STORY-NAME-KEBAB-CASE] | Dependencies: None | Parallel-safe: true | Modules: [module-c]

## Parallel Development Set for Sequential Phase 2
- Story 02-001 | [Story Title] | Branch: feature/current/[PRD-NAME-KEBAB-CASE]/story-02-001-[STORY-NAME-KEBAB-CASE] | Dependencies: 01-001, 01-002 | Parallel-safe: true | Modules: [module-a]
- Story 02-002 | [Story Title] | Branch: feature/current/[PRD-NAME-KEBAB-CASE]/story-02-002-[STORY-NAME-KEBAB-CASE] | Dependencies: 01-001, 01-003 | Parallel-safe: true | Modules: [module-b]

## Parallel Development Set for Sequential Phase 3
- Story 03-001 | [Story Title] | Branch: feature/current/[PRD-NAME-KEBAB-CASE]/story-03-001-[STORY-NAME-KEBAB-CASE] | Dependencies: 01-002, 02-001 | Parallel-safe: false | Modules: [module-x]
```

## Output Format

The generated task list _must_ follow this structure:

```markdown
## Relevant Files

- `path/to/potential/file1.mts` - Brief description of why this file is relevant (e.g., Contains the main component for this feature).
- `path/to/file1.test.mts` - Unit tests for `file1.mts`.
- `path/to/another/file.mts` - Brief description (e.g., API route handler for data submission).
- `path/to/another/file.test.mts` - Unit tests for `another/file.mts`.
- `lib/utils/helpers.mts` - Brief description (e.g., Utility functions needed for calculations).
- `lib/utils/helpers.test.mts` - Unit tests for `helpers.mts`.

### Notes

- Unit tests should typically be placed alongside the code files they are testing (e.g., `MyComponent.tsx` and `MyComponent.test.tsx` in the same directory).
- Use `bun run jest [optional/path/to/test/file]` to run tests. Running without a path executes all tests found by the Jest configuration.

## Parallel Development Sets

### Phase 01
- Story 01-001 | [Story Title] | Branch: feature/current/[PRD-NAME-KEBAB-CASE]/story-01-001-[STORY-NAME-KEBAB-CASE] | Dependencies: None | Parallel-safe: true | Modules: [module-a]
- Story 01-002 | [Story Title] | Branch: feature/current/[PRD-NAME-KEBAB-CASE]/story-01-002-[STORY-NAME-KEBAB-CASE] | Dependencies: None | Parallel-safe: true | Modules: [module-b]

### Phase 02
- Story 02-001 | [Story Title] | Branch: feature/current/[PRD-NAME-KEBAB-CASE]/story-02-001-[STORY-NAME-KEBAB-CASE] | Dependencies: 01-001 | Parallel-safe: true | Modules: [module-a]
- Story 02-002 | [Story Title] | Branch: feature/current/[PRD-NAME-KEBAB-CASE]/story-02-002-[STORY-NAME-KEBAB-CASE] | Dependencies: 01-002 | Parallel-safe: true | Modules: [module-b]
```

## Per-Story File Template (with YAML front matter)

Each story file must begin with YAML front matter followed by a structured body. Save files to `internal-docs/feature/[PRD-NAME-KEBAB-CASE]/tasks/` as `tasks-[PRD-NAME-KEBAB-CASE]-[PP]-[III]-[STORY-TITLE-KEBAB-CASE].md`.

```yaml
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
created_at: "YYYY-MM-DD"
updated_at: "YYYY-MM-DD"
---
```

```markdown
## Summary

One-paragraph description of the story, intent, and scope boundaries.

## Sub-Tasks

- [ ] Task 1 — scope and target files
- [ ] Task 2 — scope and target files

Status conventions: mark in-progress with `[~]`, done with `[x]`, blocked with `[!]`.

## Relevant Files

- `path/to/file.mts` — why relevant
- `path/to/file.test.mts` — tests for the above

## Acceptance Criteria

- [ ] Criterion 1
- [ ] Criterion 2

## Test Plan

- Unit: `bun run jest [optional/path]`
- Lint: `bun run lint` (or equivalent)
- Types: `bun run typecheck` (or equivalent)

## Observability

- Logging, metrics, traces to add; dashboards/alerts to update

## Compliance

- Note regulatory/privacy constraints; data handling; retention

## Risks & Mitigations

- Risk: … — Mitigation: …

## Dependencies & Sequencing

- Depends on: 01-001, 01-002
- Unblocks: 02-002

## Definition of Done

- Code, tests, docs updated; CI green; dashboard and story file updated

## Commit Conventions

- Use conventional commits with module scoping, e.g., `feat(moduleA): …`

## Changelog

- YYYY-MM-DD: initialized story file
```

## Interaction Model

The process explicitly requires a pause after generating parent tasks to get user confirmation ("Go") before proceeding to generate the detailed sub-tasks. This ensures the high-level plan aligns with user expectations before diving into details.

## Target Audience

Assume the primary reader of the task list is a **junior developers** who will implement the feature in parallel with other junior developers.
