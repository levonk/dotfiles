---
description: TypeScript Development Essentials
use_when:
  - "*.js"
  - "*.ts"
  - "*.tsx"
  - "*.mts"
  - "*.mjs"
  - "*.cjs"
---

# TypeScript Development Essentials

Critical Javascript Typescript Patterns

**Use when**: working with `*.js`, `*.ts`, `*.mts`, `*.mjs`, `*.tsx` files

**comprehensive docs:** .Slash AI slash rules slash software dev slash front end dev/

## See also

- General architecture aggregator: `../../general/architecture.md.tmpl`
- Modular architecture sections: `../../general/architecture/`

## Project Integration & Tooling

- **Respect Repository Configuration:** Before any edits, read and adhere to `package.json` (especially `type`, `scripts`, `packageManager`), `tsconfig.json`, `.eslintrc`, `.prettierrc`, `.editorconfig`, `.gitattributes`.
- **Package Manager:** Determine the project manager that the project is using based on the lockfile or `package.json`. If there isn't an explicit package manager defined, `bun` is the preferred package manager.
- **Use Repository Scripts:** Execute via `package.json` scripts; do not call global binaries directly. Use the detected package manager.
- **No Unsolicited Changes:** Do not modify deps or configs unless explicitly tasked.
- **Monorepo Awareness:** Operate within the affected workspace. Respect TS project references and `tsc -b` where configured.

## TypeScript standards

- **TypeScript:** Prefer >= 5.9.2 on greenfield; suggest upgrade otherwise.
- **ECMAScript Modules:** Prefer ESM on greenfield; suggest migrating from CJS/AMD/UMD.
- **Source File Naming Rule:** Use `.mts` in ESM projects and `.cts` in CommonJS projects to keep module boundaries clear; avoid mixing unless required.
- **Strict mode:** always enabled in `tsconfig.json`.
- **Eradicate `any`:** Use proper types or `unknown`.
- **no `as` casting:** fix type issues at source.
- **Explicit types:** prefer explicit over implicit.
- **interfaces versus types:** Interfaces for objects.
- **No Suppressions:** Never use `// eslint-disable`, `// @ts-ignore`, or weaken configs to hide problems.
- **Aggressive Immutability:** Enforce `const`, `readonly`, `Readonly<T>`, `as const` where applicable.
- **Modern & Safe Syntax:** Use optional chaining `?.`, nullish coalescing `??`, `Object.hasOwn()`.
- **Deterministic Diffs:** Change only what’s necessary; honor formatter and file ordering.
- **Named exports:** Prefer named exports over default exports

### Import Standards

- **Named imports:** Prefer named imports over default imports.
- **Grouped imports:** Group imports by origin
- **Relative imports:** Prefer relative imports over aliased imports i.e. `./` over `@/`.
- **Wildcard imports:** Prefer explicit imports over wildcard imports
- **Absolute imports:** Prefer relative imports over absolute imports
- **Deep imports:** Avoid deep relative imports (../../../../), if necessary, use barrel files
- **Circular imports:** Use lint or static analysis to detect circular dependencies and refactor to avoid them
- **No side effects:** Avoid side effects in imports
- **index.ts imports:** Prefer explicit paths vs. importing from index.ts

### Config Hygiene & Tooling

- **Mirror tsconfig.paths:** in ESLint and Jest configs
- **Module Boundries:** Enforce via ESLint `no-restricted-imp` that module boundaries shouldn't be violated by importing outside of exports
- **Type imports:** `type` imports are for types only.
- **style importing:** `.css` and `.scss` should use dedicated style entry points, and not be imported directly into logic files

### Agentic Stack Rules

- **Subagent import:** Avoid cross-agent leakage by having subagents importing only from scoped modules.
- **Config layers:** must be imported explicitly, not implicitly from root
- **SSR-safe imports only:** Avoid importing runtime-only modules in static contexts.

## Package Organization

Front end code is in either:

- packages/
- static/ld/
