---
description: Architecture — Tool Detection
---

# Tool Detection Architecture

- PATH detection first (e.g., `which`/`where`).
- Version verification using `--version`; fallback to `--help`.
- Cache detection results to speed subsequent runs.
- Design for variability across install methods and OSes.
- Treat detection as I/O with clear error messages and retries where reasonable.
