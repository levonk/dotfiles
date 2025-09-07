---
description: Feature Flagging Guidelines
---

# Feature Flagging Guidelines

## Purpose

Feature flags (also known as feature toggles) allow teams to modify system behavior without changing code. They enable:

- Gradual rollouts
- A/B testing
- Canary releases
- Kill switches for problematic features
- Separating deployment from release

## Implementation Requirements

### Flag Structure

- Each flag must have a clear, descriptive key using kebab-case, e.g., `checkout-payment-flow`
- Default flag type is boolean unless otherwise specified
- If the flag will be used in frontend code, ensure client-side availability is enabled
- All flags must have documentation explaining:
  - Purpose
  - Expected behavior when ON/OFF
  - Default state
  - Planned removal date (if temporary)

### Code Organization

- Feature flags should be centralized in a dedicated configuration module
- Flag access should be abstracted through a feature flag service
- Minimize flag checking in business logic
- Avoid nested flag conditions (flag pyramids)

### Creation Workflow

When asked to create a feature flag:

- Verify whether the MCP tool is available to you
- If MCP is not available, explicitly inform the requester you do not have access
- If MCP is available, use it to create the flag
- After creation, provide a direct link to the flag immediately (replace placeholders with real values):
  - Project key: PROJECT KEY
  - Flag key: FLAG KEY

#### Operator Checklist (quick steps)

- Check MCP tool access; if unavailable, clearly state lack of access
- If available, use MCP to create the flag
- Choose type: default to boolean unless there is a documented need for a different type
- If the flag is consumed by frontend code, enable client-side availability
- Follow naming conventions (see "Naming Conventions by Layer")
- Immediately share a direct link to the created flag

#### Standard Response Template (after flag creation)

Provide this structured response to ensure complete information is returned to the requester. Replace placeholders with actual values.

- Project key: PROJECT KEY
- Flag key: FLAG KEY
- Direct link: [https://feature-flags.example.com/projects/PROJECT_KEY/flags/FLAG_KEY](https://feature-flags.example.com/projects/PROJECT_KEY/flags/FLAG_KEY)
- Type: boolean (default) | `other`
- Client-side availability: Yes | No
- Default state: On | Off
- Purpose: `1-2 sentence description of what this flag controls`

### Testing

- All code paths (flag ON and OFF) must have test coverage
- Integration tests should verify both states of the flag
- Document test scenarios for both states

### Lifecycle Management

- All temporary flags must have an expiration date
- Regular audits to remove obsolete flags
- Dashboard for monitoring active flags and their states

### Naming Conventions by Layer

- Flag keys: kebab-case (e.g., `checkout-payment-flow`)
- Backend methods: PascalCase
- Frontend functions: camelCase

## Critical Commands

- TODO: Populate with organization-specific CLI/API commands for creating, updating, and deleting flags via MCP or other tooling.

## Best Practices

- Keep the number of active flags to a minimum
- Prefer using feature flags at the edge of the system
- Consider performance implications of flag checking in high-throughput code paths
- Document the flag's purpose and expected behavior
- Plan for flag removal as part of the feature development
