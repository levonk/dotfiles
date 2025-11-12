---
description: Architecture — Adding New Tools
---

# Adding New Tools

- Define CLI surface in the command layer (args, subcommands).
- Add display-name/config mapping in services or config domain.
- Extend detection/mapping; wire execution path in CLI logic domain.
- Add external service operations as needed under `services/`.
- Keep responsibilities in their domains; update tests and docs alongside changes.
