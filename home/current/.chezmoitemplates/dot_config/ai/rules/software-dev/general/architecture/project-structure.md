---
description: Architecture — Project Structure
---

# Project Structure

- Top-level entry points: minimal `main` and/or `lib` delegating to domains.
- Domains: `cli/`, `cli_logic/`, `auth/`, `config/`, `services/`, `tools/`, `theme/`, `api/`.
- Each domain exposes a clear entry module and re-exports via a local index.
- Keep modules ~150–200 LOC where practical; prefer composition over deep inheritance.
- Enforce module boundaries; import only through domain public API.

See also: `dot_config/ai/rules/software-dev/general/architecture/philosophy.md`.
