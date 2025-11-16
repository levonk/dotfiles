{{/*
Core shared analysis scaffolding for all journal analysis prompts.

Expected context (.):

- PeriodLabel: string
  One of: "Day", "Week", "Month", "Quarter", "Year", "Decade".
- PeriodName: string
  Human-readable title, e.g. "Daily Journal Analysis", "Quarterly Journal Analysis".
- RangeLabel: string (optional)
  Label for the period, e.g. "2025-11-15", "2025-W46", "2025-11", "2025-Q1", "2025", "2015–2024".
- Inputs: any
  Entries or summaries provided by the caller (daily text, weekly summaries, etc.).

This partial focuses on behavior and structure. Path/filename logic lives in journal-paths.
It is meant to be pulled in via includeTemplate from other templates.
*/}}

# {{ .PeriodName }} (Multi-Lens)

You are an AI assistant performing a **{{ .PeriodLabel }}-scale** analysis of journal material.

Your goals:

- Make this period legible to future-me across **personal**, **social**, and **professional** lenses.
- Use prior analyses when they exist; when they do not, instruct the coding agent to generate them using the appropriate workflows.
- Produce clear actions, normalized entities, and a concise summary.

Work only with the provided inputs and analyses; do not invent events.

---

## 1. Inputs Snapshot

Summarize the inputs for this {{ .PeriodLabel }}:

- State the span covered and the `RangeLabel` if available (for example, week or month label).
- Describe what you are analyzing (raw daily entries, weekly summaries, monthly summaries, etc.).
- Note any obvious gaps without speculating.

Keep this high-level; do not re-copy full entries.

---

## 2. Resolution & Canonical Paths (For Coding Agent)

For this {{ .PeriodLabel }}, the coding agent should use the canonical journal paths defined by the `journal-paths` helpers.

You may reference them in examples, but do not attempt to write files yourself. Instead, describe what the agent should do.

Examples (illustrative only; the agent will substitute real dates/labels):

- Daily path example:
  - `{{ includeTemplate "config/ai/workflows/general/comms/journal/partials/journal-paths.md.tmpl" (dict "Helper" "journalDailyPath" "Year" "2025" "Date" "2025-11-15") }}`
- Weekly path example:
  - `{{ includeTemplate "config/ai/workflows/general/comms/journal/partials/journal-paths.md.tmpl" (dict "Helper" "journalWeeklyPath" "Year" "2025" "WeekLabel" "2025-W46") }}`
- Monthly path example:
  - `{{ includeTemplate "config/ai/workflows/general/comms/journal/partials/journal-paths.md.tmpl" (dict "Helper" "journalMonthlyPath" "Year" "2025" "MonthLabel" "2025-11") }}`

Resolution escalation rules (for the coding agent):

- Whenever a higher-level analysis (Week/Month/Quarter/Year/Decade) needs lower-level summaries:
  - **If they exist**, load them from their canonical paths using the helpers in `journal-paths`.
  - **If they do not exist**, invoke the appropriate analysis workflow for that lower level
    (for example, run `journal-analysis-week` over daily entries for each missing week),
    then write the results using the canonical path.

Once lower-level analyses exist for the span, treat them as primary inputs for this {{ .PeriodLabel }} analysis, using raw entries only as needed for detail.

---

## 3. Multi-Lens Analysis

{{ includeTemplate "config/ai/workflows/general/comms/journal/partials/journal-lenses.md.tmpl" (dict "Mode" "definitions" "Context" .) }}

{{ includeTemplate "config/ai/workflows/general/comms/journal/partials/journal-lenses.md.tmpl" (dict "Mode" "core-lenses" "Context" .) }}

---

## 4. Actions & Follow-Ups

Turn insights from all lenses into a realistic set of actions.

- 3–10 actions depending on {{ .PeriodLabel }} scope.
- Use checkbox form where possible.
- Tag each action with the relevant lens or lenses, for example:
  - `[ ] (personal) Improve sleep routine`
  - `[ ] (professional) Close out PR-123 and write postmortem`

---

## 5. Major Decisions & Inflection Points

Capture consequential choices and turning points observed in this {{ .PeriodLabel }}.

**Locations (`locations` array)**

Each location should be modeled as an object with fields such as:

- `id` (optional stable ID, for example `loc:la-home`).
- `country` (default: `USA`).
- `state_or_province` (default: `CA`).
- `county` (default: `Los Angeles County`).
- `city`.
- `postal_code` (ZIP/postal code).
- `names` (array of labels/aliases, for example `['Home office', 'LA apartment']`).

**Entities (`entities` array)**

Represent people, organizations, teams, and other important actors as objects:

- `id` (for example, `p:alex`, `org:acme`, `team:infra`).
- `kind` (for example, `person`, `org`, `team`, `other`).
- `names` (array of canonical name and aliases).
- Optional `roles` (for example, `['friend', 'coworker']`).
- Optional `notes`.

Only list entities clearly grounded in the journal content or a known registry; do not invent new entities.

---

## 6. {{ .PeriodLabel }} Summary

{{ includeTemplate "config/ai/workflows/general/comms/journal/partials/journal-summary-section.md.tmpl" . }}

Aim for a summary that would still be useful to read long after this {{ .PeriodLabel }} has passed.

{{- end -}}
