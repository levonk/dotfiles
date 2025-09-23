---
agent: "Newsletter — Quarterly Customer"
slug: "newsletter-quarterly-customer"
description: "Generate the quarterly customer newsletter from the canonical template."
use: "When a quarterly customer newsletter is needed."
role: "Comms Writer"
color: "#0ea5e9"
icon: "📣"
categories: ["business", "docs", "comms"]
capabilities: ["read-templates", "draft-newsletter", "tailor-by-audience", "save-output"]
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
    description: "Create a new markdown newsletter"
    inputs:
      - { name: path, type: string, required: true, description: "Absolute path to write output" }
      - { name: contents, type: string, required: true, description: "Rendered newsletter markdown" }
    outputs:
      - { name: path, type: string, description: "Path written" }
version: 1.0.0
owner: "comms"
status: "ready"
visibility: "internal"
compliance: []
runtime:
  duration: { min: "10s", max: "90s", avg: "30s" }
  terminate: "on missing inputs or template not found"
date: { created: "YYYY-MM-DD", updated: "YYYY-MM-DD" }
defaults:
  cadence: quarterly
  audience: customer
  template: home/current/.chezmoitemplates/dot_config/ai/templates/business/comms/newsletters/quarterly-customer.md.tmpl
  output_dir: newsletters/quarterly/customer
---

# Newsletter — Quarterly Customer (Agent)

## Goal

- Produce a quarterly customer newsletter with product highlights, stories, roadmap, and events.

## Inputs

- period_key: e.g., `2025-Q3`
- owner (optional)
- highlights (optional)
- output_path (optional; defaults under `newsletters/quarterly/customer/`)

## Primary Workflow

1. Resolve template from `defaults.template`.
2. Read template; render placeholders (owner/period_key/highlights).
3. Emphasize product value, stories, roadmap themes, and events.
4. Write output to `output_path` or `{output_dir}/newsletter-quarterly-customer-{period_key}.md`.
5. Return summary.
