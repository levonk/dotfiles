---
description: Shared task definitions for software-dev task workflows
---
# Shared Task Definitions

These shared definitions are included by multiple workflow templates under `dot_config/ai/workflows/software-dev/tasks/`.
They standardize terminology and expectations for generating task lists from PRDs and similar inputs.

## Terms

- Parallel stories: Stories within the same phase that can be executed concurrently without conflicts.
- Sequential phases: Ordered phases; each phase must complete before the next begins.
- Story ID: `PP-III` where `PP` is a 2-digit phase number; `III` is a 3-digit parallel index.
- Branch naming: `feature/current/[PRD-NAME-KEBAB-CASE]/story-[PP]-[III]-[STORY-NAME-KEBAB-CASE]`.
- Relevant files: Concrete files expected to be created/updated, plus their tests.

## Required Story Metadata

Each story should declare at least:

- story_id, story_title, story_name
- prd_name, prd_file
- phase, parallel_id
- branch
- status, assignee, reviewer
- dependencies (list), parallel_safe (bool)
- modules (list), priority, risk_level, tags
- due, created_at, updated_at

## Story Body Structure

Stories should contain sections for:

- Summary: intent and scope boundaries
- Sub-Tasks: actionable steps, each referencing target files
- Relevant Files: code files and test files impacted
- Acceptance Criteria: verifiable outcomes
- Test Plan: unit, lint, types, and any e2e notes
- Observability: logging/metrics/traces updates
- Compliance: regulatory/data handling concerns
- Risks & Mitigations: notable risks and how to reduce them
- Dependencies & Sequencing: what it depends on and what it unblocks
- Definition of Done: what must be true before marking done
- Commit Conventions: e.g., conventional commits with module scoping

## Output Conventions

- Place generated story files under `internal-docs/feature/[PRD-NAME-KEBAB-CASE]/tasks/`.
- Filename pattern: `tasks-[PRD-NAME-KEBAB-CASE]-[PP]-[III]-[STORY-NAME-KEBAB-CASE].md`.
- Create a phase-index file `index-[PRD-NAME-KEBAB-CASE].md` summarizing all stories in a table with: Story ID, Title, Branch, Dependencies, Parallel-safe, Modules.

## Review Gates

Before moving from high-level stories to detailed sub-tasks:

- Present the high-level plan and wait for an explicit "Go".
- After generating sub-tasks, verify dependencies minimize merge conflicts and enable parallel work.

## Notes for AI Assistants

- If the PRD file path is not provided, ask for it explicitly.
- Keep sub-tasks small, testable, and scoped to minimize conflicts.
- Always list and update the `Relevant Files` to guide implementation and reviews.
