---
description: Feature — Domain Primitives & Branded Types (TypeScript)
use_when:
  - "**/*.ts"
  - "**/*.tsx"
  - "**/*.mts"
---

# Domain Primitives & Branded Types — TypeScript

- Create `src/domain/types/brand.ts` with a nominal branding helper.
- Define domain IDs and sensitive primitives in `src/domain/types/*.ts` using branding.
- Provide constructors/validators at boundaries; prefer `zod` or `valibot` when available.
- For runtime-light projects, keep validation at I/O edges only.

Import/Export
- Export only branded public types and constructors from `src/domain/types/index.ts`.
- Do not export internal helper brands.

Testing
- Add tests to ensure non-assignability across distinct branded types and correct constructors.

Tooling
- ESLint: disallow `any`, enforce explicit types; enable `@typescript-eslint/no-unsafe-assignment` where feasible.
- TSConfig: `strict: true`.
