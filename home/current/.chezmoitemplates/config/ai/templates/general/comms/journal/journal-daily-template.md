---
template: 'Daily Journal AI Workflow Template'
slug: 'journal-daily-template'
description: 'Reusable template describing a daily journaling AI workflow that captures events, surfaces missing-but-important items, and distills them into knowledge, reminders, and summaries.'
use: 'When designing or running a daily journaling conversation with an AI assistant.'
role: 'Scaffold/Renderer'
engine: 'markdown+ai-prompt'
aliases: ['daily-journal-template', 'reflection-journal-template']
outputs_to: ['config/ai/templates/general/comms/journal-daily.md']
variables:
  schema:
    - name: context
      type: object
      required: false
      default: {}
      description: 'Optional runtime context; for example, date, tags, current focus, or project.'
    - name: time_of_day
      type: string
      required: false
      default: 'evening'
      description: 'When this journal is usually run; for example, morning, midday, evening.'
    - name: focus
      type: string
      required: false
      default: 'balanced'
      description: "Dominant focus: 'operational', 'emotional', or 'balanced'."
partials: []
conflicts:
  strategy: 'merge'
  backup: true
validation: ['Template renders sections: Capture, Fill Gaps, Distill, Actions, Reminders, Summary']
tools:
  - name: 'ai-journal-assistant'
    description: 'AI assistant that walks through the daily journaling workflow and writes results back to the journal file or knowledge system.'
version: 1.0.0
owner: 'https://github.com/levonk'
status: 'ready'
visibility: 'internal'
compliance: ['no-secrets-in-journal']
runtime:
  duration:
    min: '5m'
    max: '25m'
    avg: '12m'
  terminate: 'When the Summary and Next Actions sections are populated and user signals done.'
date:
  created: '2025-11-15'
  updated: '2025-11-15'
tags: ['template', 'journal', 'reflection', 'daily', 'ai/template/prompt']
---

# Daily Journal AI Workflow Template

## Goal

- Provide a repeatable, AI-guided daily journaling flow.
- Ensure each session:
  - Captures what actually happened.
  - Surfaces missing-but-important details (decisions, blockers, emotions, ideas).
  - Distills insights into reusable knowledge, reminders, and concise summaries.

## Structure Overview

1. **Start & Context**

   - Confirm date, time of day, and main focus for this session.
   - Short warm-up to set intention.

2. **Raw Capture (What happened?)**

   - Log concrete events, tasks, conversations, and notable moments.
   - Allow quick bullet-style dumping before refinement.

3. **Fill the Gaps (What might be missing?)**

   - Prompt for items often forgotten; for example:
     - Decisions made or deferred.
     - Open loops, blockers, and dependencies.
     - Emotional tone or stressors.
     - New ideas, questions, or half-baked threads.

4. **Distill & Extract (What matters?)**

   - Convert raw notes into:
     - Key insights and lessons.
     - Facts worth remembering.
     - Reusable patterns or rules.

5. **Actions & Reminders (What next?)**

   - Derive actionable tasks and gentle reminders.
   - Separate:
     - Hard tasks (with owners/due dates, when known).
     - Soft reminders ("nudge me about X later" style).

6. **Summary & Compression (How to recall later?)**
   - Produce a compact summary that would make sense if re-read months later.
   - Optional: one-sentence "headline" for the day.

## Sections To Render In `journal-daily.md`

Each run of the AI prompt should walk through the following sections. The exact phrasing can vary; this template defines the _semantics_.

### 1. Session Context

- **Date / time:**
- **Time of day:** (morning / afternoon / evening)
- **Primary focus:** (operational / emotional / balanced)
- **Any specific topics to emphasize today?**

### 2. Raw Capture

- **Prompt:**
  - "List what happened today that feels notable, even if small. Use short bullets; don't worry about structure yet."
- **Output format:**
  - Bulleted list of events / tasks / moments.
  - Allow nested bullets for details.

### 3. Fill The Gaps

- **Prompts:**
  - "Did you make any decisions (big or small) today that might matter later?"
  - "What is currently blocked or worrying you?"
  - "What emotions showed up today that might be signals?"
  - "Any ideas, questions, or half-started things that future-you might want to revisit?"
- **Output format:**
  - Subsections: `Decisions`, `Blockers & Risks`, `Emotions`, `Ideas & Threads`.

### 4. Distill: Insights & Knowledge

- **Prompts:**
  - "From everything above, what seems actually important?"
  - "What did you learn or relearn today?"
  - "What might future-you want to remember as a principle, pattern, or warning?"
- **Output format:**
  - `Insights & Lessons` (bullets or short paragraphs).
  - Optional `Principles / Rules of Thumb` extracted as concise statements.

### 5. Actions & Reminders

- **Prompts:**
  - "What concrete actions follow from today?"
  - "What should future-you be gently reminded of (without turning it into a hard task)?"
- **Output format:**
  - `Action Items` list with optional fields: description, owner (default: you), and target time frame.
  - `Reminders & Nudges` list written in friendly language.

### 6. Daily Summary

- **Prompts:**
  - "If you had to summarize today for future-you in 2-5 sentences, what would you say?"
  - "Optional: What is a one-line headline for today?"
- **Output format:**
  - `Headline:`
  - `Summary:` (short paragraph).

## Usage Notes

- This template is **agnostic** to storage; it can drive:
  - Plain markdown files.
  - A spaced-repetition or PKM system.
  - AI tools that ingest and cross-link daily notes.
- The AI assistant running `journal-daily.md` should:
  - Respect the session focus (`operational`, `emotional`, or `balanced`).
  - Avoid forcing answers where nothing comes up; allow "none" openly.
  - Prefer clarity and brevity over verbosity in summaries.

<!-- vim: set ft=markdown -->
