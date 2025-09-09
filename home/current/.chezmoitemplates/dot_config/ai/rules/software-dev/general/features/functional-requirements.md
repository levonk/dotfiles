---
description: Features Spec — Functional Requirements
---

# Functional Requirements

- Selection:
  - Choose pattern/refactor, tools, languages, and scope (project, module, package, directory subtree, file, object).

- Generation produces:
  - agents
  - hooks
  - snippets
  - templates
  - rules
  - create/apply workflows

- Output:
  - Chezmoi templates and calling templates for selected tools and languages.

- Application:
  - Produce Chezmoi template markdown files in `home/current/.chezmoitemplates/dot_config/ai/{agents,hooks,snippets,templates,rules,workflows}` to operate on software, and their calling templates in the tool-appropriate output paths.

- Conventions:
  - `feature-id@vN` versioning; kebab-case ids; tool-appropriate calling templates output paths.

- Documentation:
  - Each feature has usage, scope, and examples.
