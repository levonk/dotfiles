{{- define "ai/templates/general/comms/elevator-pitch" -}}
---
modeline: "vim: set ft=markdown:"
title: "Elevator Pitch"
slug: elevator-pitch
url: ""
synopsis: "Concise elevator pitch with audience-fit and a brief follow-up explanation."
authors: ["https://github.com/levonk"]
date:
  created: "{{ now | default "" }}"
  updated: ""
version: "1.0.0"
status: "draft"
aliases: []
tags: ["doc/comms/templates", "ai/templates"]
related-to: []

# pitch variables
audience: "{{ if hasKey . "audience" }}{{ index . "audience" }}{{ else }}{{ "" }}{{ end }}"
audience_specificity: "{{ if hasKey . "audience_specificity" }}{{ index . "audience_specificity" }}{{ else }}{{ "" }}{{ end }}"
industry: "{{ if hasKey . "industry" }}{{ index . "industry" }}{{ else }}{{ "" }}{{ end }}"
listener_context: "{{ if hasKey . "listener_context" }}{{ index . "listener_context" }}{{ else }}{{ "" }}{{ end }}"
problem: "{{ if hasKey . "problem" }}{{ index . "problem" }}{{ else }}{{ "" }}{{ end }}"
tangible_outcome: "{{ if hasKey . "tangible_outcome" }}{{ index . "tangible_outcome" }}{{ else }}{{ "" }}{{ end }}"
mechanism: "{{ if hasKey . "mechanism" }}{{ index . "mechanism" }}{{ else }}{{ "" }}{{ end }}"
differentiation: "{{ if hasKey . "differentiation" }}{{ index . "differentiation" }}{{ else }}{{ "" }}{{ end }}"
credibility_proof: "{{ if hasKey . "credibility_proof" }}{{ index . "credibility_proof" }}{{ else }}{{ "" }}{{ end }}"
call_to_action: "{{ if hasKey . "call_to_action" }}{{ index . "call_to_action" }}{{ else }}{{ "" }}{{ end }}"
tone: "{{ if hasKey . "tone" }}{{ index . "tone" }}{{ else }}{{ "" }}{{ end }}"
length_seconds: {{ if hasKey . "length_seconds" }}{{ index . "length_seconds" }}{{ else }}20{{ end }}
vocabulary_level: "{{ if hasKey . "vocabulary_level" }}{{ index . "vocabulary_level" }}{{ else }}plain-language{{ end }}"
constraints: "{{ if hasKey . "constraints" }}{{ index . "constraints" }}{{ else }}no NDAs violated; no private data; no unverified claims{{ end }}"
follow_up_depth: "{{ if hasKey . "follow_up_depth" }}{{ index . "follow_up_depth" }}{{ else }}one-paragraph explanation{{ end }}"
delivery_format: "{{ if hasKey . "delivery_format" }}{{ index . "delivery_format" }}{{ else }}spoken-first{{ end }}"
---

<!-- elevator-pitch.md (rendered) -->

# Elevator Pitch

{{- /* One to three sentences; ~20 seconds when spoken */ -}}
{{- /* Compose outcome-first, with problem → outcome → mechanism → proof → CTA */ -}}

{{- /* Example structure (rendered from provided variables): */ -}}
{{- /* Problem in listener's words */ -}}
{{- $problem := .problem -}}
{{- $outcome := .tangible_outcome -}}
{{- $mechanism := .mechanism -}}
{{- $diff := .differentiation -}}
{{- $proof := .credibility_proof -}}
{{- $cta := .call_to_action -}}

{{- /* Main pitch: keep to 1–3 sentences */ -}}
{{- if $problem -}}We help with {{ $problem }}. {{- end -}}
{{- if $outcome }} You get {{ $outcome }}.{{ end -}}
{{- if $mechanism }} We do this by {{ $mechanism }}.{{ end -}}
{{- if $diff }} Unlike alternatives, {{ $diff }}.{{ end -}}
{{- if $cta }} Next step: {{ $cta }}.{{ end -}}

## Follow-Up (How it works and why it matters)

{{- /* One short paragraph explaining mechanism, differentiation, and fit */ -}}
{{- if and $mechanism $diff -}}
{{ printf "In short, our approach works by %s, and it stands out because %s." $mechanism $diff }}
{{- else if $mechanism -}}
{{ printf "In short, our approach works by %s." $mechanism }}
{{- else if $diff -}}
{{ printf "It stands out because %s." $diff }}
{{- else -}}
We focus on clear outcomes and a low-friction path to value.
{{- end }}

{{- end -}}
