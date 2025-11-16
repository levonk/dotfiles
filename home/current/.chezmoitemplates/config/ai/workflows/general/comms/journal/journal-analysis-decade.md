---
template: 'Journal Analysis Decade'
slug: 'journal-analysis-decade'
description: 'Analyze a decade of life across personal, social, and professional lenses to surface deep patterns and life-shaping themes.'
use: 'Run occasionally (for example, at decade boundaries) to understand long-term arcs.'
role: 'AI Prompt'
engine: 'markdown+ai-prompt'
aliases: ['decade-review', 'journal-decade-analysis']
outputs_to: []
variables:
  schema:
    - name: entries
      type: array
      required: true
      default: []
      description: 'High-level yearly or milestone summaries spanning roughly a decade.'
    - name: decade_label
      type: string
      required: false
      default: ''
      description: 'Optional label for the decade, for example 2015–2024.'
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
  ['Produces sections: Inputs, Personal Lens, Social Lens, Professional Lens, Life Themes, Future Orientation, Summary']
version: 1.0.0
date:
  created: '2025-11-15'
  updated: '2025-11-15'
{{- /* Journal meta partial supplies metadata; override runtime for decade reviews. */ -}}
{{ includeTemplate "config/ai/workflows/general/comms/journal/partials/journal-meta.md.tmpl" (dict
  "runtimeMin" "45m"
  "runtimeMax" "90m"
  "runtimeAvg" "60m"
  "runtimeTerminate" "When deep life themes and forward-looking intentions for the next era are clear."
  "tags" (list "prompt" "journal" "analysis" "decade")) }}
---

# Decade Journal Analysis (Multi-Lens)

You are an AI assistant performing a **decade-scale review**.

Your goals:

- Understand the last decade across **personal**, **social**, and **professional** lenses.
- Surface deep patterns and life-shaping themes.
- Help articulate how to move into the next era intentionally.

Use only the content in `entries`; do not invent.

---

## 1. Inputs Snapshot

- Describe the span covered and the types of entries (yearly summaries, major milestones).
- Note any big external markers (moves, career changes, major relationships) as recorded.

---

{{ includeTemplate "config/ai/workflows/general/comms/journal/partials/journal-analysis-core.md" (dict
  "PeriodLabel" "Decade"
  "PeriodName" "Decade Journal Analysis"
  "RangeLabel" .decade_label
  "Inputs" .entries
) }}

---

## 5. Life Themes

Identify 3–10 life themes that characterize this decade.

For each theme:

- Name.
- Examples across multiple years and lenses.
- How this theme served or harmed you.

---

## 6. Future Orientation

Based on the themes and lenses, articulate how to move into the next era:

- What to keep and deepen.
- What to gently release.
- What new experiments to try.

Output:

- 3–7 forward-looking intentions.
- Optional: a short "letter to future-me" capturing what matters most.

---

<!-- vim: set ft=markdown -->
