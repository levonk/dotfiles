---
template: 'Journal Analysis Quarter'
slug: 'journal-analysis-quarter'
description: 'Analyze the last quarter of journal entries across personal, social, and professional lenses to surface trends and course corrections.'
use: 'Run once per quarter to review and compress the last 3 months of entries.'
role: 'AI Prompt'
engine: 'markdown+ai-prompt'
aliases: ['quarterly-review', 'journal-quarterly-analysis']
outputs_to: []
variables:
  schema:
    - name: entries
      type: array
      required: true
      default: []
      description: 'Journal snippets or summaries (daily/weekly/monthly) for the quarter.'
    - name: quarter_label
      type: string
      required: false
      default: ''
      description: 'Optional label for the quarter, for example 2025-Q1.'
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
  ['Produces sections: Inputs, Personal Lens, Social Lens, Professional Lens, Cross-Lens Themes, Course Corrections, Summary']
version: 1.0.0
date:
  created: '2025-11-15'
  updated: '2025-11-15'
{{- /* Journal meta partial supplies metadata; override runtime for quarterly reviews. */ -}}
{{ includeTemplate "config/ai/templates/general/comms/journal/partials/journal-meta.md.tmpl" (dict
  "runtimeMin" "20m"
  "runtimeMax" "45m"
  "runtimeAvg" "30m"
  "runtimeTerminate" "When cross-lens themes and course corrections for the quarter are clear."
  "tags" (list "prompt" "journal" "analysis" "quarter")) }}
---

# Quarterly Journal Analysis (Multi-Lens)

You are an AI assistant performing a **quarterly review**.

Your goals:

- Understand how the quarter looked from **personal**, **social**, and **professional** perspectives.
- Identify cross-lens themes and trends.
- Propose a compact set of course corrections for the next quarter.

Use only the content in `entries`; do not invent.

---

## 1. Inputs Snapshot

- Summarize the time span (first and last dates) and rough density of entries.
- Note any large gaps without speculating.

---

{{ includeTemplate "config/ai/workflows/general/comms/journal/partials/journal-analysis-core.md" (dict
  "PeriodLabel" "Quarter"
  "PeriodName" "Quarterly Journal Analysis"
  "RangeLabel" .quarter_label
  "Inputs" .entries
) }}

---

## 5. Cross-Lens Themes

Identify 3–7 themes that cut across the lenses.

For each theme:

- Name.
- 2–5 short examples tagged with lens (personal/social/professional).
- One-sentence interpretation of what this means for future-you.

---

## 6. Course Corrections for Next Quarter

Propose focused adjustments based on the themes:

- 3–7 course corrections (e.g., "rebalance personal vs professional energy", "nurture relationship X", "starve project Y").
- Actionable items in checkbox form, linked to themes and lenses when possible.

Keep this list concise and realistic.

---

<!-- vim: set ft=markdown -->
