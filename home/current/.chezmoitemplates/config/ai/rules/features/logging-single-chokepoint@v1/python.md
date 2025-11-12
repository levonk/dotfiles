---
description: Feature — Single Chokepoint Logging (Python)
use_when:
  - "**/*.py"
---

# Single Chokepoint Logging — Python

- Create `app/infra/logging/logger.py` as the single logging facade.
- Support level filtering and JSON/plain formats via adapter functions.
- Provide redaction/minimization helpers in `app/infra/logging/redact.py` when needed.
- Expose only the facade from `app/infra/logging/__init__.py`.

Testing
- Unit-test level filtering and field inclusion/exclusion.

Tooling
- Enforce a single import path for logging via linter rule/docs guidance.
