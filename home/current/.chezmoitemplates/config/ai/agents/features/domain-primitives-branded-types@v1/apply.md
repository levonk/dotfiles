---
description: Agent — Apply Feature domain-primitives-branded-types@v1
---

# Agent: Apply Domain Primitives & Branded Types @ v1

- Read repo config; detect TS/Py
- For TS: create `src/domain/types/brand.ts` and `index.ts` from templates; add example branded types as snippets; update exports
- For Py: create `app/domain/types/__init__.py` and `newtypes.py` with NewType declarations
- Preserve behavior; non-destructive updates only
- Run lints/tests; propose commit
