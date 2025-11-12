# People Ops — Status Report Agents

Agents that generate status reports from the canonical templates in:
`home/current/.chezmoitemplates/dot_config/ai/templates/business/people-ops/`

- Base agent: `status-report-writer.md`
- Wrappers: preconfigured period and audience (weekly/quarterly/annual × leadership/peers/team/all)

Usage (conceptual)
- Invoke the wrapper agent for the desired audience and period.
- Provide `period_key` (e.g., `2025-09-15..2025-09-21`, `2025-Q3`, or `2025`).
- Optional inputs: `owner`, `team`, and a custom `output_path`.

Output
- A Markdown report written under `reports/status/<period>/<audience>/` by default.
