---
template: 'Journal Analysis Year'
slug: 'journal-analysis-year'
description: 'Analyze the last year of journal entries across personal, social, and professional lenses to understand major arcs and inflection points.'
use: 'Run once per year to review and compress the last year into clear narratives and decisions.'
role: 'AI Prompt'
engine: 'markdown+ai-prompt'
aliases: ['yearly-review', 'journal-yearly-analysis']
outputs_to: []
variables:
  schema:
    - name: entries
      type: array
      required: true
      default: []
      description: 'Monthly and/or quarterly summaries and key entries for the year.'
    - name: year_label
      type: string
      required: false
      default: ''
      description: 'Optional label for the year, for example 2025.'
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
  ['Produces sections: Inputs, Personal Lens, Social Lens, Professional Lens, Major Decisions, Long-Arc Themes, Summary']
version: 1.0.0
date:
  created: '2025-11-15'
  updated: '2025-11-15'
{{- /* Journal meta partial supplies metadata; override runtime for yearly reviews. */ -}}
{{ includeTemplate "config/ai/workflows/general/comms/journal/partials/journal-meta.md.tmpl" (dict
  "runtimeMin" "30m"
  "runtimeMax" "60m"
  "runtimeAvg" "40m"
  "runtimeTerminate" "When long-arc themes and key decisions for the year are clear."
  "tags" (list "prompt" "journal" "analysis" "year")) }}
---

# Yearly Journal Analysis (Multi-Lens)

You are an AI assistant performing a **yearly review**.

Your goals:

- Describe the year from **personal**, **social**, and **professional** perspectives.
- Identify long-arc themes and inflection points.
- Make the year legible to future-you in a compact way.

Use only the content in `entries`; do not invent.

---

## 1. Inputs Snapshot

- State the year and rough coverage (months with entries, gaps).
- Note any major known events referenced in the entries.

---

{{ includeTemplate "config/ai/workflows/general/comms/journal/partials/journal-analysis-core.md" (dict
  "PeriodLabel" "Year"
  "PeriodName" "Yearly Journal Analysis"
  "RangeLabel" .year_label
  "Inputs" .entries
) }}

---

## 5. Major Decisions & Inflection Points

From across the entries, gather:

- Major decisions and why they were made (as recorded at the time).
- Inflection points where direction changed.

For each, briefly note:

- Date (or approximate).
- Lens/lenses primarily involved (personal/social/professional).
- Whether, in hindsight, it feels aligned or misaligned.

---

## 6. Long-Arc Themes & Intentions

Identify 3–7 long-arc themes that describe the year as a whole.

For each theme:

- Name.
- Examples from different times in the year.
- Intentions for how to relate to this theme next year (continue, rebalance, or retire).

---

<!-- vim: set ft=markdown -->
