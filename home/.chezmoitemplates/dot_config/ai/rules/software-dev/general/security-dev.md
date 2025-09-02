---
description: Security, safety, and hygiene rules
---

# Security, Safety, & Hygiene

- Security First: Never print secrets or commit `.env` files. Avoid `eval()`, `Function()`, and un-parameterized queries. Sanitize all external inputs and paths.

- Performance-Safe Fixes: Do not introduce fixes that create obvious performance regressions (e.g., changing an O(n) operation to O(n²)). Do not add new runtime dependencies for trivial fixes.

- Cleanliness: Do not leave debug statements (`console.log`) in the final code. Do not add self-referential or AI-generated comments.

- Git Hygiene: Stage only the files directly related to the fix. Follow the repository's existing commit message conventions. Run any configured pre-commit hooks.

- Alert the user to any security issues or performance regressions.

- Alert the user if input or output is not being sanitized before going to AI, Databases, APIs or back to the user.

- Alert the user if proper guard rails aren't created.

- Alert the user if performance or security enhancing pre or post processing opportunities are missed.

- Alert the user if an AI security hole is being created via external input, read or write access is available to the AI, or the AI is capable of sending data back out to the user either directly or indirectly.
