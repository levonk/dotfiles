---
agent: "Recognition Digest"
slug: "recognition-digest"
description: "Aggregate recent recognition notices (people, projects, milestones) into a single internal digest."
use: "When sharing a weekly/monthly internal roundup of recognition."
role: "Comms Aggregator"
color: "#16a34a"
icon: "📬"
categories: ["business", "docs", "comms"]
capabilities: ["read-templates", "read-sources", "draft-digest", "save-output"]
model-level: "default"
model: ""
tools:
  - name: "read_file"
    description: "Open and read files in workspace"
    inputs:
      - { name: path, type: string, required: true, description: "Absolute path to source doc or template" }
    outputs:
      - { name: contents, type: string, description: "File contents" }
  - name: "write_file"
    description: "Create a new markdown digest"
    inputs:
      - { name: path, type: string, required: true, description: "Absolute path to write output" }
      - { name: contents, type: string, required: true, description: "Rendered markdown" }
    outputs:
      - { name: path, type: string, description: "Path written" }
version: 1.0.0
owner: "comms"
status: "ready"
visibility: "internal"
compliance: []
runtime:
  duration: { min: "10s", max: "120s", avg: "45s" }
  terminate: "on missing inputs or template not found"
date: { created: "YYYY-MM-DD", updated: "YYYY-MM-DD" }
defaults:
  template: home/current/.chezmoitemplates/dot_config/ai/templates/business/comms/recognition/recognition-digest.md.tmpl
  output_dir: comms/recognition/digests
---

# Recognition Digest (Agent)

## Goal

- Produce a concise internal digest summarizing recent recognition notices with links for amplification.

## Inputs

- period_key: `YYYY-MM-DD..YYYY-MM-DD`
- sources (optional): glob(s) to recognition items, e.g., `comms/recognition/**/*.{md,mdx}`
- audience: internal
- output_path (optional; defaults under `comms/recognition/digests/`)

## Primary Workflow

1. Gather sources (default directories and/or provided globs).
2. Extract People/Projects/Milestones items with title/summary/link.
3. Render digest via the template.
4. Write output to `output_path` or `{output_dir}/recognition-digest-{period_key}.md`.
5. Return summary.
