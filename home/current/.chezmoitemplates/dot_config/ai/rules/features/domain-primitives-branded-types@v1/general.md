---
description: Feature — Domain Primitives & Branded Types (General)
---

# Domain Primitives & Branded Types — General

Establish domain-safe primitive types to prevent accidental mixing of logically distinct values that share the same runtime type (e.g., `UserId` vs `OrderId` as strings). Provide:

- Branded or opaque types for identifiers and sensitive primitives.
- Centralized module(s) under `src/domain/types/` (TS) or `app/domain/types/` (Python).
- Constructors/validators and safe formatting helpers.
- No runtime overhead where possible; validation at boundaries.

Outcomes:
- Compile-time separation of distinct concepts.
- Safer function signatures; reduced accidental misuse.
- Easier refactors with constrained blast radius.
