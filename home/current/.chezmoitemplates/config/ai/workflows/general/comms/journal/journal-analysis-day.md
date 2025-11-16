---
template: 'Journal Analysis Day'
slug: 'journal-analysis-day'
description: 'Analyze a single day of journal entries across personal, social, and professional lenses.'
use: 'Run after a daily journal session to separate and compress the day into multiple lenses.'
role: 'AI Prompt'
engine: 'markdown+ai-prompt'
aliases: ['daily-review', 'journal-daily-analysis']
outputs_to: []
variables:
  schema:
    - name: entry
      type: string
      required: true
      default: ''
      description: 'The full daily journal entry or consolidated text for the day.'
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
  ['Produces sections: Inputs, Personal Lens, Social Lens, Professional Lens, Actions, Summary']
version: 1.0.0
date:
  created: '2025-11-15'
  updated: '2025-11-15'
{{- /* Journal meta partial supplies metadata; override runtime for daily analysis. */ -}}
{{ includeTemplate "config/ai/workflows/general/comms/journal/partials/journal-meta.md.tmpl" (dict
  "runtimeMin" "5m"
  "runtimeMax" "20m"
  "runtimeAvg" "10m"
  "runtimeTerminate" "When lenses and next actions for the day are clearly articulated."
  "tags" (list "prompt" "journal" "analysis" "day")) }}
---

{{ includeTemplate "config/ai/workflows/general/comms/journal/partials/journal-analysis-core.md" (dict
  "PeriodLabel" "Day"
  "PeriodName" "Daily Journal Analysis"
  "RangeLabel" ""
  "Inputs" .entry
) }}

<!-- vim: set ft=markdown -->
