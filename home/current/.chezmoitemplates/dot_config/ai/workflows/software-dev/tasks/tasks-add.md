---
description: Add a task from chat via /tasks-add and persist it to internal-docs/tasks
---

# /tasks-add Workflow

- __Slash command__
  - Trigger from chat:
    - Minimal: `/tasks-add "Implement nightly backup monitoring"`
    - Full: `/tasks-add summary="Implement nightly backup monitoring" details="Track job results and alert on failure" priority="high" tags="infra,alerts"`

- __Inputs__
  - summary: short, one-line title. If omitted, the first positional argument is used.
  - details: optional freeform description or acceptance criteria.
  - priority: low | medium | high (default: medium).
  - tags: comma-separated labels (e.g., platform,infra,bug,docs).

- __Output__
  - Creates a task file at `internal-docs/tasks/task-YYYYMMDD-HHMMSS-<kebab-title>.md` with YAML frontmatter and sections.
  - Ensures directory `internal-docs/tasks/` exists.
  - Appends a checklist line to `internal-docs/tasks/backlog.md` (created if missing).

## Shared Task Definitions

{{ includeTemplate "dot_config/ai/workflows/software-dev/tasks/tasks.md" . }}

1) Parse inputs and set defaults
   - If only a single positional string is given, treat it as `summary`.
   - Default `priority` is `medium`; default `tags` is empty.

// turbo
1) Ensure tasks directory exists
   
   ```bash
   mkdir -p internal-docs/tasks
   ```

// turbo
1) Create a kebab-case slug from the summary and write the task file
   
   ```bash
   set -euo pipefail
   SUMMARY=${TASK_SUMMARY:-${1:-"New Task"}}
   DETAILS=${TASK_DETAILS:-""}
   PRIORITY=${TASK_PRIORITY:-medium}
   TAGS=${TASK_TAGS:-""}
   now_ts=$(date +%Y%m%d-%H%M%S)
   slug=$(printf "%s" "$SUMMARY" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/-/g; s/-+/-/g; s/^-|-$//g')
   file="internal-docs/tasks/task-${now_ts}-${slug:-task}.md"
   created_at=$(date +%F)
   mkdir -p internal-docs/tasks
   cat > "$file" <<TASK
---
title: $SUMMARY
created_at: $created_at
updated_at: $created_at
status: todo
priority: $PRIORITY
assignee: ""
reviewer: ""
tags: [$(printf "%s" "$TAGS" | awk -F, '{for(i=1;i<=NF;i++){gsub(/^\s+|\s+$/,"",$i); if($i!=""){printf (i>1?", ":"")"\"%s\"", $i)}}')]
---

## Summary

$SUMMARY

## Details

${DETAILS}

## Sub-Tasks

- [ ] Define acceptance criteria
- [ ] Implement
- [ ] Validate

## Acceptance Criteria

- [ ] Criterion 1
- [ ] Criterion 2

## Links

- related:
TASK
   echo "$file"
   ```


// turbo
1) Append to backlog index

   
   {{ includeTemplate "dot_config/ai/workflows/software-dev/tasks/tasks-backlog-append.md" . }}


1) Next steps

   - Offer to open the created task file and help flesh out details.
   - Optionally add the task into a planning board or sprint doc if configured.
