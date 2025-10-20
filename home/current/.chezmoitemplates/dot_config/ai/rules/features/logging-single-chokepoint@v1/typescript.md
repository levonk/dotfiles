---
description: Feature — Single Chokepoint Logging (TypeScript)
use_when:
  - "**/*.ts"
  - "**/*.tsx"
  - "**/*.mts"
---

# Single Chokepoint Logging — TypeScript

- Create `src/infra/logging/logger.ts` as the single logging facade.
- Support level filtering and JSON/plain formats via adapter functions.
- Provide redaction/minimization helpers in `src/infra/logging/redact.ts` when needed.
- Expose only the facade from `src/infra/logging/index.ts`.

Testing
- Unit-test level filtering and field inclusion/exclusion.

Tooling
- Enforce explicit levels; disallow console usage outside the facade.
