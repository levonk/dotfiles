---
description: Architecture — Philosophy
---

# Architecture Philosophy

- Domain-based modular architecture with clear separation of concerns.
- Clear entry points per domain; thin top-level (`main`/`lib`) that delegate.
- Focused modules with single responsibility; small, testable units.
- Coordination via local index/re-export modules; avoid cross-domain leakage.
- Benefits: maintainability, testability, extensibility, refactoring safety.

See also: `dot_config/ai/rules/software-dev/general/architecture/project-structure.md`.
