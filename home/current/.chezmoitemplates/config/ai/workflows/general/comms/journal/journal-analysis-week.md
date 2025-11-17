---
includeTemplate: 'Journal Analysis Week'
slug: 'journal-analysis-week'
description: 'Analyze the last week of journal entries to surface themes, decisions, risks, and next steps.'
use: 'Run once per week to review and compress the last 7 days of daily journal entries.'
role: 'AI Prompt'
engine: 'markdown+ai-prompt'
aliases: ['weekly-review', 'journal-weekly-analysis']
outputs_to: []
variables:
  schema:
    - name: entries
      type: array
      required: true
      default: []
      description: 'A collection of daily journal snippets or links for the last 7 days.'
    - name: week_label
      type: string
      required: false
      default: ''
      description: 'Optional label for the week, for example 2025-W46.'
partials:
  - 'journal/partials/journal-meta.md.tmpl'
  - 'journal/partials/journal-summary-section.md.tmpl'
  - 'journal/partials/journal-lenses.md.tmpl'
  - 'journal/partials/journal-paths.md.tmpl'
  - 'journal/partials/journal-analysis-core.md'
conflicts:
  strategy: 'merge'
  backup: true
validation: ['Produces sections: Inputs, Highlights, Themes, Decisions, Risks, Actions, Summary']
version: 1.0.0
date:
  created: '2025-11-15'
  updated: '2025-11-15'
{{- /* Journal meta partial will supply owner/status/visibility/compliance/runtime/tags.
      Override runtime defaults for weekly reviews via the context we pass at render time. */ -}}
{{- $inputs := (list) -}}
{{- if hasKey . "entries" -}}
  {{- $inputs = .entries -}}
{{- end -}}
{{- $label := "" -}}
{{- if hasKey . "week_label" -}}
  {{- $label = .week_label -}}
{{- end -}}
{{ includeTemplate "config/ai/workflows/general/comms/journal/partials/journal-meta.md.tmpl" (dict
  "runtimeMin" "10m"
  "runtimeMax" "30m"
  "runtimeAvg" "20m"
  "runtimeTerminate" "When themes and focus for the upcoming week are clear."
  "tags" (list "prompt" "journal" "analysis" "week")) }}
---

# Weekly Journal Analysis

You are an AI assistant performing a **weekly review** over the last 7 days of journal entries.

Your goals:

- Extract the **most important events, themes, and decisions** from the week.
- Surface **risks, blockers, and trends** that might need attention.

{{- /* Compute robust inputs and label for include contexts */ -}}
{{- $inputs := (list) -}}
{{- if hasKey . "entries" -}}
  {{- $inputs = .entries -}}
{{- end -}}
{{- $label := "" -}}
{{- if hasKey . "week_label" -}}
  {{- $label = .week_label -}}
{{- end -}}

{{ includeTemplate "config/ai/workflows/general/comms/journal/partials/journal-analysis-core.md" (dict
  "PeriodLabel" "Week"
  "PeriodName" "Weekly Journal Analysis"
  "RangeLabel" $label
  "Inputs" $inputs
) }}

## 5. Actions & Focus for Next Week

Turn insights into a focused plan for the coming week.

- 3–7 **focus areas** for next week.
- Action items in checkbox form, for example:
  - `- [ ] Description (linked to a theme or decision)`

Prioritize clarity and realism over volume.

## 7. Weekly Summary

{{ includeTemplate "config/ai/workflows/general/comms/journal/partials/journal-summary-section.md.tmpl" . }}

<!-- vim: set ft=markdown -->
