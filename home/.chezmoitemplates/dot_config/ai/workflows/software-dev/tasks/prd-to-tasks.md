# Rule: Generating a Task List from a PRD

## Goal

To guide an AI assistant in creating a detailed, step-by-step task list in Markdown format based on an existing Product Requirements Document (PRD). The task list should guide a developer through implementation.

## Output

- **Format:** Markdown (`.md`)
- **Location:** `internal-docs/feature/[prd-name]/tasks/`
- **Filename:** `tasks-[prd-file-name]-[STORY-PARALLEL-PHASE]-[STORY-PARALLEL-ID]-[STORY-TITLE-NO-SPACES].md` (e.g., `tasks-prd-user-handling-1-1-user-tables.md`, `tasks-prd-user-handling-2-1-user-signup-api.md`, `tasks-prd-user-handling-2-2-user-signup-mock-service.md`, etc.)

## Process

1. **Receive PRD Reference:** The user points the AI to a specific PRD file. If you didn't get this you must ask for it.
2. **Analyze PRD:** The AI reads and analyzes the functional requirements, user stories, and other sections of the specified PRD.
3. **Phase 1: Generate Parallel Story Sets:** Based on the PRD analysis, propose sequential phases. Within each phase, define parallel stories that can be developed simultaneously. Organize stories for **PARALLEL** execution using Git worktrees. Present only the high-level story list first (no sub-tasks yet). Inform the user: "I have generated the high-level tasks based on the PRD. Ready to generate the sub-tasks? Respond with 'Go' to proceed."
4. **Wait for Confirmation:** Pause and wait for the user to respond with "Go", "Ok", "Yes", or similar.
5. **Phase 2: Generate Sub-Tasks:** Once confirmed, for each story create smaller, actionable sub-tasks. Ensure sub-tasks logically follow from dependencies and minimize merge conflicts by scoping changes.
6. **Identify Relevant Files:** Based on the tasks and PRD, identify potential files that will need to be created or modified. List these under the `Relevant Files` section, including corresponding test files if applicable.
7. **Generate Final Output:** Combine the parent tasks, sub-tasks, relevant files, and notes into the final Markdown structure.
8. **Save Task List:** Save each story document to `internal-docs/feature/[prd-name]/tasks/` using the filename `tasks-[prd-file-name]-[2-DIGIT-STORY-PARALLEL-PHASE]-[3-DIGIT-STORY-PARALLEL-ID]-[STORY-TITLE-NO-SPACES].md`.

## Numbering Scheme and Branch Naming

- **Use this numbering scheme:**
  - **Parallel stories**: Can be developed simultaneously within the same sequential phase.
  - **Sequential phases**: Phases must be completed in order; each phase contains a set of parallel stories.
- **For each story, include:**
  - **Story ID**: `PP-III` where `PP` is 2-digit phase, `III` is 3-digit parallel index (e.g., `01-001`).
  - **Worktree branch name**: `feature/current/[PRD-TITLE-NO-SPACES]/story-[PP]-[III]-[STORY-TITLE-NO-SPACES]`.
  - **Dependencies**: Prior stories (e.g., `01-001, 01-002`).
  - **Parallel safe**: `true/false`.
  - **Modules/areas impacted**: Call out directories or services to minimize conflicts.

### Example Structure

```markdown
## Parallel Development Set for Sequential Phase 1
- Story 01-001 | [Story Title] | Branch: feature/current/[PRD-TITLE-NO-SPACES]/story-01-001-[STORY-TITLE-NO-SPACES] | Dependencies: None | Parallel-safe: true | Modules: [module-a]
- Story 01-002 | [Story Title] | Branch: feature/current/[PRD-TITLE-NO-SPACES]/story-01-002-[STORY-TITLE-NO-SPACES] | Dependencies: None | Parallel-safe: true | Modules: [module-b]
- Story 01-003 | [Story Title] | Branch: feature/current/[PRD-TITLE-NO-SPACES]/story-01-003-[STORY-TITLE-NO-SPACES] | Dependencies: None | Parallel-safe: true | Modules: [module-c]

## Parallel Development Set for Sequential Phase 2
- Story 02-001 | [Story Title] | Branch: feature/current/[PRD-TITLE-NO-SPACES]/story-02-001-[STORY-TITLE-NO-SPACES] | Dependencies: 01-001, 01-002 | Parallel-safe: true | Modules: [module-a]
- Story 02-002 | [Story Title] | Branch: feature/current/[PRD-TITLE-NO-SPACES]/story-02-002-[STORY-TITLE-NO-SPACES] | Dependencies: 01-001, 01-003 | Parallel-safe: true | Modules: [module-b]

## Parallel Development Set for Sequential Phase 3
- Story 03-001 | [Story Title] | Branch: feature/current/[PRD-TITLE-NO-SPACES]/story-03-001-[STORY-TITLE-NO-SPACES] | Dependencies: 01-002, 02-001 | Parallel-safe: false | Modules: [module-x]
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
- Story 01-001 | [Story Title] | Branch: feature/current/[PRD-TITLE-NO-SPACES]/story-01-001-[STORY-TITLE-NO-SPACES] | Dependencies: None | Parallel-safe: true | Modules: [module-a]
- Story 01-002 | [Story Title] | Branch: feature/current/[PRD-TITLE-NO-SPACES]/story-01-002-[STORY-TITLE-NO-SPACES] | Dependencies: None | Parallel-safe: true | Modules: [module-b]

### Phase 02
- Story 02-001 | [Story Title] | Branch: feature/current/[PRD-TITLE-NO-SPACES]/story-02-001-[STORY-TITLE-NO-SPACES] | Dependencies: 01-001 | Parallel-safe: true | Modules: [module-a]
- Story 02-002 | [Story Title] | Branch: feature/current/[PRD-TITLE-NO-SPACES]/story-02-002-[STORY-TITLE-NO-SPACES] | Dependencies: 01-002 | Parallel-safe: true | Modules: [module-b]
```

## Interaction Model

The process explicitly requires a pause after generating parent tasks to get user confirmation ("Go") before proceeding to generate the detailed sub-tasks. This ensures the high-level plan aligns with user expectations before diving into details.

## Target Audience

Assume the primary reader of the task list is a **junior developers** who will implement the feature in parallel with other junior developers.
