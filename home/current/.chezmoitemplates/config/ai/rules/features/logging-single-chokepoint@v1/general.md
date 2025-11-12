---
description: Feature — Single Chokepoint Logging with Filtering (General)
---

# Single Chokepoint Logging — General

Establish a centralized logging module as the single entry point for application logs. Provide:

- Single logger facade; internal adapters for stdout, file, JSON, or structured logs.
- Log level filtering, redact/minimize helpers for sensitive data.
- Consistent log fields: timestamp, level, component, message, context.
- Placement: `src/infra/logging/` (TS) or `app/infra/logging/` (Python).

Outcomes:
- Uniform logs; easy to swap sinks and formats.
- Reduced duplication; filtering consistently applied.
- Safer logging of sensitive data.
