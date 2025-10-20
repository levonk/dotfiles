---
description: Patterns/Features automation spec
status: draft
owner: platform-devx
last_updated: 2025-09-08
links:
  - ./ToolSupport.md
  - ./LanguageSupport.md
  - ./Patterns.md
  - ./Refactorings.md
  - ./CodeSmells.md
---

- **Create**
	- workflows
	- rules
	- templates
	- agents
	- hooks
	- snippets


# Patterns/Features Automation - Spec

## Overview
Standardize and automate how patterns, refactorings, and jobs are created and applied across tools and languages using ChezMoi as the single source of truth. Ship reusable artifacts (workflows, rules, agents, hooks, templates, snippets) and provide safe, idempotent refactors by scope: project, module, package, directory subtree, file, or object.

## Goals
- Consistent automation for common patterns and refactors.
- One canonical place to define generation and application.
- Tool- and language-aware outputs via ChezMoi templates.
- Put the files into sensible subdirectories under `home/current/.chezmoitemplates/ai/{agents,rules,workflows,hooks,templates,snippets}`. look at `dot_config/ai/{rules,workflows}` for examples.
- Idempotent application;

## Non-Goals
- Building custom IDE plugins from scratch.
- Storing secrets or PII in templates or generated artifacts.
- Public marketplace; this is internal DX.

## Scope
- Artifacts: workflows, rules, agents, hooks, templates, snippets.
- Targets: tools listed in `ToolSupport.md`; languages listed in `LanguageSupport.md`.
- Domains: `Patterns.md`, `Refactorings.md`, `CodeSmells.md`.

## Functional Requirements
- Selection: choose pattern/refactor, tools, languages, and scope.
- Generation: produce:
	- agents
	- hooks
	- snippets
	- templates
	- rules
	- plus create/apply workflows.
- Output:
- Application: This is not an application, produce chezmoi template markdown files in `home/current/chezmoitemplates/dot_config/ai/{agents,hooks,snippets,templates,rules,workflows}` to operate on software, and their calling templates in the tool approriate output paths
- Conventions: `feature-id@vN` versioning; kebab-case ids; tool-appropriate calling templates output paths.
- Documentation: each feature has usage, scope, examples.

## Non-Functional Requirements
- Safety: no secrets/PII; confirm destructive ops.
- Portability: Linux/macOS; Windows
- Lint: markdownlint for docs; JSON sanity; shellcheck/shfmt for scripts.
- Traceability: workflows log changed files and targets.

## Repository Layout
- Canonical source templates and assets:
  - `home/current/.chezmoitemplates/ai/{agents,rules,workflows,hooks,templates,snippets}/`
- Specs and catalogs:
  - `internal-docs/specs/2025/202509/20250907Patterns/{Patterns.md,Refactorings.md,CodeSmells.md}`
- Scripts (optional): `scripts/ai/` for generation/validation.

## Acceptance Criteria
- Artifacts exist for at least two tools and two languages (TS, Python; Windsurf/VS Code/Cursor, Claude Code).

## Initial Feature Set (v1)
- Domain primitives and branded types.
- Read-once and tainted objects.
- Single chokepoint logging with filtering.
- Integration interfaces.
- Core data transformations: redact, minimize, tokenize, hash, encrypt, mask.

## Questions
### Open Questions

### Answered Questions
- Adopt a canonical JSON schema now
- Where should per-project overrides live (`.vscode/`, `.claude/`, both)?
	- Per project would be in the project directory, that's not in scope for this request to generate generic sets of these rules that apply to all applications using that language/technology
- Which additional AI tools from `ToolSupport.md` are in v1?
	- Windsurf, Windsurf-Next,
	- https://github.com/BA-CalderonMorales/terminal-jarvis should bundle Claude Code, gemini-cli, OpenAI codex, opencode, etc...
	- Google gemini-cli
	- Cursor
	- VSCode (copilot)
	- OpenAI Codex

## Appendix: Original Notes

- Create
  - workflows
  - rules
  - agents
  - hooks
  - snippets
  - templates
- For the following tools [[ToolSupport.md]]
- In the following [[LanguageSupport.md]]
- To
  - create the pattern/job
  - refactor the {system,project,modules, package, directory subtree,file,object} to implement the pattern/job
- Of the following patterns/jobs/refactorings
  - [[CodeSmells.md]]
  - [[Features.md]]
  - [[Patterns.md]]
  - [[Refactorings.md]]
- In `home/current/.chezmoitemplates/ai/{agents,rules,workflows,hooks,templates,snippets}`
- Using ChezMoi templating functionality for this ChezMoi home directory project
