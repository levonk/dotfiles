---
agent: "Monthly Status — Team"
slug: "status-monthly-team"
description: "Generate a monthly status report for the team from the canonical template."
use: "When a monthly team status is needed."
role: "Docs Generator"
color: "#ea580c"
icon: "🛠️"
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
  audience: team
  template: home/current/.chezmoitemplates/dot_config/ai/templates/business/people-ops/status-monthly-team.md.tmpl
  output_dir: reports/status/monthly/team
---

# Monthly Status — Team (Agent)

## Goal

- Produce a monthly team status emphasizing outcomes, MoM metrics, learnings, growth, and recognition.

## Inputs

- period_key: e.g., `2025-09`
- owner (optional)
- team (optional)
- include_recognition_digest (optional; default: false)
- recognition_digest_key (optional) — e.g., `2025-09`
- recognition_digest_path (optional) — if set, overrides key
- include_feedback_digest (optional; default: false)
- feedback_digest_key (optional) — e.g., `2025-09`
- feedback_digest_path (optional) — if set, overrides key
- include_testimonials_digest (optional; default: false)
- testimonials_digest_key (optional) — e.g., `2025-09`
- testimonials_digest_path (optional) — if set, overrides key
- output_path (optional; defaults under `reports/status/monthly/team/`)

## Primary Workflow

1. Resolve template from `defaults.template`.
2. Read template; render placeholders (owner/team/period_key).
3. Emphasize delivery, quality, retro items, growth, and recognition.
4. If `include_recognition_digest`, append a short "Recognition Digest" section using `recognition_digest_path` or by resolving `comms/recognition/digests/recognition-digest-{recognition_digest_key}.md`.
5. If `include_feedback_digest` or `include_testimonials_digest`, append a short "Feedback & Testimonials" section resolved by the respective path or key (if present).
6. Write output to `output_path` or `{output_dir}/status-monthly-team-{period_key}.md`.
7. Return summary.
