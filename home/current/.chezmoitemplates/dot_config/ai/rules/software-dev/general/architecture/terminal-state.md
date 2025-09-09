---
description: Architecture — Terminal State Management
---

# Terminal State Management

- Use minimal terminal control sequences; avoid clearing buffers unexpectedly.
- Prepare terminal state for tools that require input focus.
- Add short, intentional delays when launching tools to avoid race conditions.
- Centralize terminal state helpers; make them theme-aware when applicable.
