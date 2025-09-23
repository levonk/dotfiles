---
agent: "Quarterly Status — Peers"
slug: "status-quarterly-peers"
description: "Generate a quarterly status for peer teams from the canonical template."
use: "When a quarterly cross-team status is needed."
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
    description: "Create a new markdown review"
    inputs:
      - { name: path, type: string, required: true, description: "Absolute path to write output" }
      - { name: contents, type: string, required: true, description: "Rendered markdown" }
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
  period: quarterly
  audience: peers
  template: home/current/.chezmoitemplates/dot_config/ai/templates/business/people-ops/status-quarterly-peers.md.tmpl
  output_dir: reports/status/quarterly/peers
---

# Quarterly Status — Peers (Agent)

## Goal
- Produce a quarterly status for peers emphasizing dependencies, collaboration, roadmap coordination.

## Inputs
- period_key: e.g., `2025-Q3`
- owner (optional)
- team (optional)
- output_path (optional; defaults under `reports/status/quarterly/peers/`)

## Primary Workflow
1. Resolve template from `defaults.template`.
2. Read template; render placeholders (owner/team/period_key).
3. Emphasize cross-team dependencies, collaboration, and joint priorities.
4. Write output to `output_path` or `{output_dir}/status-quarterly-peers-{period_key}.md`.
5. Return summary.
