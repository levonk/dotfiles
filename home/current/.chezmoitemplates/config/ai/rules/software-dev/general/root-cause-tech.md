---
description: Root-cause first policy
---
## Root-Cause First Policy

Band-aids / work-arounds are unacceptable. Treat every failure as a symptom and identify the underlying cause before applying any workaround.

- **Diagnose deeply**: reproduce reliably, collect minimal failing cases, and trace the exact failing code path or configuration.
- **Fix at the source**: prefer durable, maintainable fixes at the origin (script, config, dependency, or environment contract).
- **Document clearly**: when an issue is identified, include rationale, reproduce, commit-id first noticed, scope, and environment in the following places:
  - an issue markdown file in `internal-docs/issues/open/issue-{issueNumber}-{synopsis}.md` using github issue format with the following frontmatter.
    - `description: {synopsis}`
    - `commit-id-first-noticed: {commit-id}`
    - `commit-id-bisected: {commit-id}`
    - `branch: {branch-name}`
    - `scope: {scope}`
    - `date-created: {YYYY-MM-DD}`
    - `date-resolved: {YYYY-MM-DD}`
    - `date-updated: {YYYY-MM-DD}`
    - `assignee: {assignee}`
    - `issue-number: {issue-number}`
    - `severity: {low|medium|high}`
    - `status: {draft|open|in-progress|blocked|resolved|workaround}`
    - `deployed-to: {prod|staging|qa|canary|beta|dev}`
    - `dependencies: [dependencies]`
    - `dependants: [dependants]`
    - `references: [references]`
    - `environment: [environment]`
  - a checklist (`- [ ]`) summary item in `internal-docs/issues/issues-index.md` in the `## Open` section linking to the issue markdown file.
  - a checklist plan in `internal-docs/issues/issue-{issueNumber}_plan.md` that includes the tasks here and any others necessary
  - `## TODO: ...` in-code comment summarizing the workaround and contingency to remove it
- **Workarounds are last resort**: only use a temporary guard or skip when:
  - The upstream/root fix is infeasible, and
  - The workaround is safe, minimal, documented, and tracked for removal.
  - update the issue with the workaround rationale, scope, contingency to remove it


## Testing and Root-Cause Guide

Goal: Quickly find and fix issues surfaced by any tooling or app (not just lint or hangs). Start with fast local checks; then reproduce in a clean container; iterate from the first failing step without starting from scratch.

### Prereqs

  - Tools: identify any tools that will help diagnose or resolve the issue

### First Steps

1. Make sure you understand the issue, ask questions if you need clarification
2. Check if there is already an existing issue to continue from or at least identify if there is already a blocker noted that isn't unblocked
3. If there isn't already an issue, create one.
4. Check to see if there are any docs, rules, pretaining to this issue. If there are understand them, and add references in the issue.
5. Check to see what test tooling is avialable in the project, and understand it.
6. Check to see what mock services are available in the project, and understand them.
7. Check to see what logging is available in the project, and understand it.
8. Check to see what faker data is available in the project, and understand it.
9. Check to see what data is available in the project, and understand it.
10. Check to see what contracts are available in the project, and understand them.
11. Check to see what feature flags are available in the project, and understand them.

### Plan and Prepare

1. One of the tasks should be Assure you have all the tools you need to diagnose the issue
2. Have a clear, isolated, and .devcontainerized environment to diagnose the issue. do NOT do it in a production environments (especially shared / operational data stores)
3. If there is a risk of an unreasonable delay (infinite loop, etc.), be sure timeouts are set to prevent the issue from lasting too long during the testing process.
4. Make sure the feature flags are enabled.
5. recreate the issue in the environment
6. Come up with likely suspects, and tasks to resolve the issue
7. Use git-bisect to find the first commit that introduced the issue to narrow down the problem space
8. Likely suspects should be based on the issue description, git-history, and any docs, rules, previous conversations
9. Create a new branch from the current branch on a `issue/current/issue-{issueNumber}-{synopsis}` branch
10. Create a worktree (parallel to the current project root on the filesystem) from the new branch
11. Identify if an assertion/contracts framework is available, if not, add one if available
12. Identify if necessary mocking services is available, if not, add one if available
13. Identify if logging is available, if not, add one if available
14. Identify if faker data is necessary and is available, if not, add it if a framework is available, or create it directly if one isn't
15. Identify if necessary data is available, if not, create faker data
16. If you don't have all the tools you need, explain why, explain how to get them, and ask if you can get them
17. If you add tools, commit the changes
18. Make sure the mocks are running and available.
19. Make sure the data environment and fake data is available.

### First Steps

1. perform quick sanity tests first to avoid time-wasting
2. add pre-condition, post-condition, and invarient assertions around the likely suspects
3. add debug logging to the likely suspects
4. get to recreating the issue with all the debugging tools available
5. Analyze the new data, and update the plan (including marking complete what has been done, and revising the plan if necssary)

### Iterate From First Failing Step

1. If a test/lint fails, re-run only that failing test/check until it passes.

### Cleanup

1. Rerun all tests and lints to ensure the issue is fully resolved and new ones weren't introduced
2. If any new issues are discovered along the way, create a new issues and plan, and continue from the first steps
3. update the issue with the final resolution
4. `git mv` the issue and issue plan to `internal-docs/issues/{resolved|workaround|blocked}/`
5. update the issue checklist in `internal-docs/issues/issues-index.md` to mark the issue as resolved and into the `## Resolved|Workaround|Blocked` section
6. if a workaround was necsesary, add a checklist (`- [ ]`) summary item in `internal-docs/issues/workarounds.md`
7. Update `AGENTS.md` with this general process if it doesn't already exist in case somebody tries to root cause without these rules
8. Update `AGENTS.md` with any current or new tools, mocks, data, etc. that weren't documented already
9. Update `AGENTS.md` with any likely to re-occur issues or troubleshooting/deployment steps
