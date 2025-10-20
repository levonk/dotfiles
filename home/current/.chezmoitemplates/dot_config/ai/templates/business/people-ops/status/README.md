# People Ops — Status Templates

This folder organizes status report templates by audience and cadence.
Filenames explicitly describe what the template is, independent of path.

## Structure

- `all/` — cross-audience templates (useful for anyone)
- `client/` — for client-facing updates
- `leadership/` — for leadership/exec stakeholders
- `manager/` — for direct manager updates
- `peers/` — for cross-team peers
- `team/` — for direct team updates

## Naming convention

- `status-<audience>-<cadence>.md.tmpl`

- Examples:
  - `status-all-daily.md.tmpl`
  - `status-client-weekly.md.tmpl`
  - `status-leadership-monthly.md.tmpl`
  - `status-manager-weekly.md.tmpl`
  - `status-peers-quarterly.md.tmpl`
  - `status-team-annual.md.tmpl`

## Cadences supported

- `daily`, `weekly`, `monthly`, `quarterly`, `annual`

## Canonical daily template

- Use `all/status-all-daily.md.tmpl` for general daily updates.
- A legacy file named `daily-update.md.tmpl` has been removed in favor of the
  canonical `status/all/status-all-daily.md.tmpl`.

## How to add a new template

1. Pick the audience folder (`all`, `client`, `leadership`, `manager`, `peers`, `team`).
2. Name the file `status-<audience>-<cadence>.md.tmpl`.
3. Keep frontmatter consistent with nearby templates.

## Rationale

- Clear filenames help when searching or listing files outside of context.
- Audience folders keep discovery simple for users navigating by stakeholder.
