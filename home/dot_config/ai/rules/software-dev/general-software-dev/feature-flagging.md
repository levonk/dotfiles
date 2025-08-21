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
- Each flag must have a clear, descriptive name following the pattern: `FEATURE_[COMPONENT]_[FUNCTIONALITY]`
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

### Testing
- All code paths (flag ON and OFF) must have test coverage
- Integration tests should verify both states of the flag
- Document test scenarios for both states

### Lifecycle Management
- All temporary flags must have an expiration date
- Regular audits to remove obsolete flags
- Dashboard for monitoring active flags and their states

## Best Practices
- Keep the number of active flags to a minimum
- Prefer using feature flags at the edge of the system
- Consider performance implications of flag checking in high-throughput code paths
- Document the flag's purpose and expected behavior
- Plan for flag removal as part of the feature development
