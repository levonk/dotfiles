# TypeScript Development Essentials

Critical Javascript Typescript Patterns

**Use when**: working with `*.js`, `*.ts`, `*.mts`, `*.mjs`, `*.tsx` files

**comprehensive docs:** .Slash AI slash rules slash software dev slash front end dev/

## Package Manager
- Determine the project manager that the project is using based on the lockfile or `package.json`
- If there isn't an explicit package manager defined,`bun` is the preferred package manager.

## TypeScript standards
- **Strict mode:** always enabled in `tsconfig.json`
- **No `any`:** Use proper types or `unknown`
- **no `as` casting:** fix type issues at source
- **Explicit types:** prefer explicit over implicit
- **interfaces versus types:** Interfaces for objects 

## Package Organization

Front end code is in either:
- packages/ 
- static/ld/