# Backlog Append Snippet

{{/*
Include-only snippet; not a standalone workflow.
Purpose: append the most recently created task file name to internal-docs/tasks/backlog.md,
creating the backlog file if missing, and avoiding duplicate lines.
Included by: tasks-add.md via includeTemplate("dot_config/ai/workflows/software-dev/tasks/tasks-backlog-append.md").
Reusable in any workflow that creates internal-docs/tasks/task-*.md files.
*/}}

// turbo
4) Append to backlog index

```bash
set -euo pipefail
last=$(ls -1t internal-docs/tasks/task-*.md 2>/dev/null | head -n1 || true)
mkdir -p internal-docs/tasks
if [ -f internal-docs/tasks/backlog.md ]; then
  grep -q "$(basename "$last")" internal-docs/tasks/backlog.md 2>/dev/null || echo "- [ ] $(basename "$last")" >> internal-docs/tasks/backlog.md
else
  printf "# Backlog\n\n" > internal-docs/tasks/backlog.md
  [ -n "$last" ] && echo "- [ ] $(basename "$last")" >> internal-docs/tasks/backlog.md
fi
echo "$last"
```
