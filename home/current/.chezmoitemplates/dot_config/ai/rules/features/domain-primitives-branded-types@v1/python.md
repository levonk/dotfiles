---
description: Feature — Domain Primitives & Branded Types (Python)
use_when:
  - "**/*.py"
---

# Domain Primitives & Branded Types — Python

- Prefer `typing.NewType` for lightweight branded identifiers.
- For data validation at edges, use `pydantic`/`pydantic-core` or `attrs` validators when available.
- Group domain types under `app/domain/types/` and expose from `__init__.py`.
- Keep runtime overhead minimal; validate at I/O boundaries.

Example
- `UserId = NewType('UserId', str)` and `OrderId = NewType('OrderId', str)` are incompatible at type-check time.

Testing
- Run `mypy`/`pyright` to ensure non-assignability across distinct `NewType`s.
