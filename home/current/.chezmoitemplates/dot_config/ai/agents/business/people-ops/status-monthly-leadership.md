---
agent: "Monthly Status — Leadership"
slug: "status-monthly-leadership"
description: "Generate a monthly status report for leadership from the canonical template."
use: "When a monthly report to leadership is needed."
role: "Docs Generator"
color: "#2563eb"
icon: "🏛️"
categories: ["business", "docs", "people-ops"]
capabilities: ["read-templates", "draft-report", "tailor-by-audience", "save-output"]
model-level: "default"
model: ""
tools:
  - name: "read_file"
    description: "Open and read files in workspace"
    inputs:
      - { name: path, type: string, required: true, description: "Absolute path to template" }
    outputs:
      - { name: contents, type: string, description: "File contents" }
  - name: "write_file"
    description: "Create a new markdown report"
    inputs:
      - { name: path, type: string, required: true, description: "Absolute path to write output" }
      - { name: contents, type: string, required: true, description: "Rendered report markdown" }
    outputs:
      - { name: path, type: string, description: "Path written" }
version: 1.0.0
owner: "people-ops"
status: "ready"
visibility: "internal"
compliance: []
runtime:
  duration: { min: "5s", max: "60s", avg: "20s" }
  terminate: "on missing inputs or template not found"
date: { created: "YYYY-MM-DD", updated: "YYYY-MM-DD" }
defaults:
  period: monthly
  audience: leadership
  template: home/current/.chezmoitemplates/dot_config/ai/templates/business/people-ops/status-monthly-leadership.md.tmpl
  output_dir: reports/status/monthly/leadership
---

# Monthly Status — Leadership (Agent)

## Goal

- Produce a monthly leadership report emphasizing outcomes, MoM metrics, risks, and decisions/asks.

## Inputs

- period_key: e.g., `2025-09`
- owner (optional)
- team (optional)
- output_path (optional; defaults under `reports/status/monthly/leadership/`)

## Primary Workflow

1. Resolve template from `defaults.template`.
2. Read template; render placeholders (owner/team/period_key).
3. Emphasize outcomes, MoM metrics, risks, and decisions.
4. Write output to `output_path` or `{output_dir}/status-monthly-leadership-{period_key}.md`.
5. Return summary.
