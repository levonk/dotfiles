---
description: Feature Flagging in Code
---

# Feature Flagging in Code

## Best Practices

- Use feature flags to control the rollout of new features
- Keep flag evaluation fast and side-effect free
- Use sensible defaults for when the flag service is unavailable
- Document all feature flags and their purposes
- Set up monitoring for flag usage
- Clean up unused flags

## Implementation Guidelines

- Use a consistent naming convention for flags
- Consider the performance impact of flag checks
- Be mindful of flag state in distributed systems
- Plan for flag removal as part of your development process
- Consider the impact on caching and CDN

## Example

```typescript
// Example of a feature flag check
if (featureFlags.isEnabled('new-checkout-flow', { userId })) {
  // New implementation
} else {
  // Old implementation
}
```
