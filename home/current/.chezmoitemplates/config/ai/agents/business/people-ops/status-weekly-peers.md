---
agent: "Weekly Status — Peers"
slug: "status-weekly-peers"
description: "Generate a weekly status report for peer teams from the canonical template."
use: "When a weekly report for partner teams is needed."
role: "Docs Generator"
color: "#059669"
icon: "🤝"
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
  period: weekly
  audience: peers
  template: home/current/.chezmoitemplates/dot_config/ai/templates/business/people-ops/status-weekly-peers.md.tmpl
  output_dir: reports/status/weekly/peers
---

# Weekly Status — Peers (Agent)

## Goal

- Produce a weekly report for peers emphasizing dependencies, coordination, and joint priorities.

## Inputs

- period_key: e.g., `2025-09-15..2025-09-21`
- owner (optional)
- team (optional)
- output_path (optional; defaults under `reports/status/weekly/peers/`)

## Primary Workflow

1. Resolve template from `defaults.template`.
2. Read template; render placeholders (owner/team/period_key).
3. Emphasize cross-team dependencies, collaboration, and asks.
4. Write output to `output_path` or `{output_dir}/status-weekly-peers-{period_key}.md`.
5. Return summary.
