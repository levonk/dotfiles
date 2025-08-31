---
description:
Use-when:
  - "*.js"
  - "*.ts"
  - "*.tsx"
  - "*.mts"
  - "*.mjs"
  - "*.cjs"
---
# TypeScript Development Essentials

## Project Integration & Tooling

	- **Respect Repository Configuration:** Before any edits, you must read and adhere to the project's configuration files: `package.json` (especially `type`, `scripts`, `packageManager`), `tsconfig.json`, `.eslintrc`, `.prettierrc`, `.editorconfig`, and `.gitattributes`.

	- **Package Manager:** Use `mise` to manage platforms, virtual environsment, and package managers. For greenfield projects use `bun` package manager. For brownfield projects use the detected package manager (`bun`, `npm`, `pnpm`, `yarn`).

	- **Use Repository Scripts:** **Always** execute tools via the configured `package.json` scripts (e.g., `npm run test`, `pnpm -F <pkg> build`). Do not call global binaries directly. Use the detected package manager (in priority order `bun`, `pnpm`, `yarn`, `npm`).

	- **No Unsolicited Changes:** Do **not** add, update, or remove dependencies. Do not change configuration files, scripts, or compiler flags unless that is the explicit task.

	- **Monorepo Awareness:** Operate within the scope of the affected package/workspace. Use scoping flags where appropriate (e.g., `pnpm -F <pkg>`). Respect TypeScript project references and use `tsc -b` where configured.

## Code Standards: Strict & Modern

	- **TypeScript:** Greenfield projects should use TypeScript >=5.9.2, and prompt to update to TypeScript if the project is not using TypeScript.

	- **ECMAScript Modules:** Greenfield projects should use ESM, and prompt to update to ESM if the project is using CommonJS, AMD, or UMD.

	- **Source File Naming Rule:** To ensure consistent module resolution and avoid runtime surprises, all source files must use `.mts` in ESM projects and `.cts` in CommonJS projects. Avoid using `.ts`, `.js`, `.mjs`, `.cjs` unless explicitly required for compatibility. This keeps our module boundaries clear and tooling behavior predictable.

	- **Strict mode:** always enabled in `tsconfig.json`
	- **no `as` casting:** fix type issues at source
	- **Explicit types:** prefer explicit over implicit
	- **interfaces versus types:** Interfaces for objects 

	- **No Suppressions, Ever:** **Never** use suppression comments like `// eslint-disable`, `// @ts-ignore`, `// @ts-nocheck`, or `// biome-ignore`. Do not weaken configuration files to hide problems. Address the root cause.

	- **Aggressive Immutability:** Enforce `const`-correctness for all variables that are not reassigned. Use `readonly`, `Readonly<T>`, and `as const` to ensure compile-time immutability.

	- **Eradicate `any`:** The `any` type is forbidden. Prefer `unknown` with type guards, precise interfaces, generics, discriminated unions, and schema validation for external data. If `any` is truly unavoidable at a boundary, isolate it and narrow its type immediately.

	- **Modern & Safe Syntax:** Proactively refactor older patterns to their modern, safer equivalents (e.g., use optional chaining `?.`, nullish coalescing `??`, and `Object.hasOwn()`).

	- **Deterministic Diffs:** Change only the code necessary to address the issue. Preserve comments, whitespace, and file ordering. Honor the project's formatter, encoding, and line endings.

---

## Package Organization

Front end code is in either:
- packages/ 
- static/ld/
