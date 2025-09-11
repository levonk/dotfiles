---
slug:
project-name: {name of project containing this feature}
project-slug: {slug of project containing this feature}
feature-status: draft|planning|ready|in-progress|testing|complete|deprecated
version:
title:
feature-name:
aliases:
  -
date-created: {YYYY-MM-DD}
ticket-id:
ticket-link:
dependencies:
  -
dependents:
  -
related:
  -
tags:
  - doc/requirements/feature
  -
---

# Feature: {feature-name}

ticket-id: [{ticket-id}]({ticket-link})

{feature-synopsis}

## Feature details

### Description

#### How It Works

[Describe the basic flow - what happens when someone uses this feature? Keep it simple and user-focused]

### Testing

```bash
{Command to trigger tests}
```

#### Feature Test
1. [Step 1 - how to trigger/use the feature]
2. [Step 2 - what to expect]
3. [Step 3 - how to verify it's working]

#### Feature Test Gaps

#### Feature coverage completed tests

### Technical Details

#### Dependencies Changed/Added

#### Modules Changed/Added

#### Files Changed/Added

- `path/to/main/file.js` - {Brief description of what this file does}
- `path/to/another/file.css` - {Brief description}
- `path/to/test/file.test.js` - {What test covers}

#### Key Functions/Components

**[Main Function/Component Name]**

- **What it does:** [Simple explanation]
- **Located in:** `file/path`

**[Secondary Function/Component Name]**

- **What it does:** [Simple explanation]
- **Located in:** `file/path`

[List any new packages, libraries, or external services this feature needs - or write "None"]

## Notes & TODOs

- [Any important things to remember about this feature]
- [Known issues or limitations]
- [Future improvements planned]
