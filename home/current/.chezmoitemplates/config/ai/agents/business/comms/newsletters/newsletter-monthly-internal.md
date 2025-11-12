---
agent: "Newsletter — Monthly Internal"
slug: "newsletter-monthly-internal"
description: "Generate the monthly internal newsletter from the canonical template."
use: "When a monthly internal newsletter is needed."
role: "Comms Writer"
color: "#2563eb"
icon: "🏢"
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
  cadence: monthly
  audience: internal
  template: home/current/.chezmoitemplates/dot_config/ai/templates/business/comms/newsletters/monthly-internal.md.tmpl
  output_dir: newsletters/monthly/internal
---

# Newsletter — Monthly Internal (Agent)

## Goal

- Produce a monthly internal newsletter with top highlights and clear CTAs.

## Inputs

- period_key: e.g., `2025-09`
- owner (optional)
- highlights (optional)
- include_recognition_digest (optional; default: false)
- recognition_digest_key (optional) — e.g., `2025-09`
- recognition_digest_path (optional) — if set, overrides key
- include_feedback_digest (optional; default: false)
- feedback_digest_key (optional) — e.g., `2025-09`
- feedback_digest_path (optional) — if set, overrides key
- include_testimonials_digest (optional; default: false)
- testimonials_digest_key (optional) — e.g., `2025-09`
- testimonials_digest_path (optional) — if set, overrides key
- output_path (optional; defaults under `newsletters/monthly/internal/`)

## Primary Workflow

1. Resolve template from `defaults.template`.
2. Read template; render placeholders (owner/period_key/highlights).
3. Emphasize cross-functional wins, roadmap updates, and upcoming dates.
4. If `include_recognition_digest`, append a short "Recognition Digest" section using `recognition_digest_path` or by resolving `comms/recognition/digests/recognition-digest-{recognition_digest_key}.md`.
5. If `include_feedback_digest` or `include_testimonials_digest`, append a short "Feedback & Testimonials" section resolved by the respective path or key (if present).
6. Write output to `output_path` or `{output_dir}/newsletter-monthly-internal-{period_key}.md`.
7. Return summary.
