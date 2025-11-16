---
template: 'Journal Analysis Month'
slug: 'journal-analysis-month'
description: 'Analyze the last month of journal entries to consolidate themes, progress, and course corrections.'
use: 'Run once per month to review and compress the last month of daily/weekly journal entries.'
role: 'AI Prompt'
engine: 'markdown+ai-prompt'
aliases: ['monthly-review', 'journal-monthly-analysis']
outputs_to: []
variables:
  schema:
    - name: entries
      type: array
      required: true
      default: []
      description: 'Daily and/or weekly journal snippets for the last month.'
    - name: month_label
      type: string
      required: false
      default: ''
      description: 'Optional label for the month, for example 2025-11.'
partials:
  - 'journal/partials/journal-meta.md.tmpl'
  - 'journal/partials/journal-summary-section.md.tmpl'
  - 'journal/partials/journal-lenses.md.tmpl'
  - 'journal/partials/journal-paths.md.tmpl'
  - 'journal/partials/journal-analysis-core.md'
conflicts:
  strategy: 'merge'
  backup: true
validation:
  ['Produces sections: Inputs, Major Themes, Progress, Regressions, Decisions, Course Corrections, Summary']
version: 1.0.0
date:
  created: '2025-11-15'
  updated: '2025-11-15'
{{- /* Journal meta partial will supply owner/status/visibility/compliance/runtime/tags.
      Override runtime defaults for monthly reviews via the context we pass at render time. */ -}}
{{ includeTemplate "config/ai/workflows/general/comms/journal/partials/journal-meta.md.tmpl" (dict
  "runtimeMin" "15m"
  "runtimeMax" "40m"
  "runtimeAvg" "25m"
  "runtimeTerminate" "When themes and focus for the upcoming month are clear."
  "tags" (list "prompt" "journal" "analysis" "month")) }}
---

# Monthly Journal Analysis

You are an AI assistant performing a **monthly review** over the last month of journal entries.

Your goals:

- Identify the **major themes** of the month.
- Track **progress vs. stagnation** in key areas.
- Surface **decisions and turning points**.
- Propose **course corrections** for the next month.

Use only the content in `entries`; do not invent.

---

## 1. Inputs Snapshot

- List the span covered (first and last dates).
- Rough counts: number of days with entries, number of weekly reviews (if any).

---

{{ includeTemplate "config/ai/workflows/general/comms/journal/partials/journal-analysis-core.md" (dict
  "PeriodLabel" "Month"
  "PeriodName" "Monthly Journal Analysis"
  "RangeLabel" .month_label
  "Inputs" .entries
) }}

<!-- vim: set ft=markdown -->
