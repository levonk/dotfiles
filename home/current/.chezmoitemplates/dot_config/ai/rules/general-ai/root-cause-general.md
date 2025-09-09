---
description: Root-cause first guide (general, non-coding)
---
## Root-Cause First Policy

Band-aids or quick work-arounds are unacceptable. Treat every failure as a symptom; identify and address the underlying cause before applying any temporary mitigation.

- **Diagnose deeply**: reproduce reliably, isolate the smallest failing case, and trace the exact step, rule, or assumption that breaks.
- **Fix at the source**: prefer durable fixes at the origin (policy, configuration, process, data contract, dependency, or environment).
- **Workarounds are last resort**: only when a root fix is not immediately feasible; keep the workaround safe, minimal, documented, and tracked for removal.
- **Document clearly**: capture rationale, reproduction, scope, environment, and ownership so others can verify and learn.

## Scope
Use this guide for any non-coding issue, including but not limited to:
- Operational runbooks, policies, or SOPs producing unexpected outcomes
- Tooling or CLI behaviors not tied to code changes
- Knowledge-base or content rules (formatting, prompts, templates) causing errors
- Data quality, migration, or access issues
- Human-in-the-loop processes (handoffs, SLAs, approvals) breaking expectations

## Prereqs
- Identify which tools, access, and stakeholders are needed to diagnose (logs, dashboards, analytics, tickets, calendars, docs, data samples).
- Confirm baseline assumptions and definitions (terms, SLO/SLAs, acceptance criteria, data contracts).

## First Steps
1. Clarify the problem and outcome desired; ask precise questions if anything is ambiguous.
2. Check existing issues or incident reports. If one exists, continue there; avoid forking efforts.
3. If none exists, create a new issue with a short title, summary, and initial reproduce notes.
4. Locate and read any relevant policies, rules, SOPs, playbooks, or knowledge articles. Link them in the issue.
5. Identify available test environments, data sets, or sandboxes to reproduce safely.

## Plan and Prepare
1. List the minimal tools/data needed to reproduce (who can provide access if missing).
2. Work in an isolated, reversible environment (staging/sandbox; never production) where changes can be rolled back.
3. Apply time limits to risky steps to avoid long waits or loops.
4. Reproduce the issue end-to-end and log timestamps, inputs, and outputs.
5. Draft likely causes based on the description, history, and documentation; outline experiments to confirm or eliminate them.
6. If historical analysis is useful, review related changes, announcements, policy updates, or calendar events to correlate timing.

## Investigate
- Create a minimal, repeatable scenario. Remove variables until the issue disappears; the last removed item is a strong suspect.
- Add lightweight assertions and checkpoints (pre-/post-conditions) in the process; record each outcome.
- Capture evidence: screenshots, logs, transcripts, sample inputs/outputs, timestamps.
- Compare expected vs. actual at each step; identify the first divergence.
- Engage relevant owners (policy author, data steward, process owner) when the divergence crosses boundaries.

## Iterate From First Failing Step
- Do not restart from the beginning each time. Re-run only the smallest failing step with controlled inputs.
- Change one variable at a time; record the effect.
- When the root cause is confirmed, design the fix at the source. Validate with the same minimal scenario, then a full-path rehearsal.

## Communication and Documentation
- Update the issue with:
  - Reproduction steps, environment, and minimal failing case
  - Root cause statement and evidence
  - Decision record for the fix or, if necessary, the temporary workaround
  - Owner(s), due dates, and any follow-ups
- If a workaround is used, include the removal criteria and add a checklist item in the index of workarounds.

## Cleanup
1. Verify the fix in the isolated environment; then validate in the standard environment.
2. Re-run related checks to catch regressions in neighboring areas.
3. Close the issue with references to the updated policies/SOPs/data contracts.
4. Announce changes to stakeholders if behavior or procedures changed.

## Issue Template (frontmatter example)
Use this when creating a non-coding issue record.

- description: <synopsis>
- owner: <name or team>
- date-created: <YYYY-MM-DD>
- date-updated: <YYYY-MM-DD>
- date-resolved: <YYYY-MM-DD>
- severity: <low|medium|high>
- status: <draft|open|in-progress|blocked|resolved|workaround>
- environment: [staging|sandbox|prod|other]
- dependencies: [list]
- dependants: [list]
- references: [docs/links]
- removal-criteria-if-workaround: <conditions to remove temporary mitigations>
