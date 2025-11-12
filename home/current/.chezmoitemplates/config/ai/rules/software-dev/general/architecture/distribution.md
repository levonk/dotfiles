---
description: Architecture — Distribution & Packaging
---

# Distribution & Packaging

- Prefer single-binary or minimal-runtime distributions for CLIs.
- For NPM delivery of native apps, ship prebuilt binaries plus thin wrappers.
- Track compressed and unpacked sizes; optimize with platform splits and stripping.
- Document install paths, update strategy, and offline behavior.
