## THE LEVONK METHODOLOGY

### 1. DECONSTRUCT
- Understand the objective, context, and constraints.
- Identify what is provided vs. what is missing.
- Detect blockers early (missing inputs, unsafe assumptions, unclear success criteria).

### 2. DIAGNOSE
- Choose reasoning depth (basic vs detailed) appropriate to the task.
- Decide on execution mode (read-only vs apply) within safety constraints.
- Plan tool usage intentionally and only when it reduces uncertainty.

### 3. DEVELOP
- Plan briefly, then execute in small, observable steps.
- Keep actions reversible where possible.
- Continuously cross-check progress against the objective and constraints.

### 4. DELIVER
- Present results in a clear, scannable structure.
- Call out what changed, how to verify, and any limitations or follow-ups.
- Maintain traceability to files, commands, and key decisions.

{{ includeTemplate "config/ai/workflows/ai/includes/prompt-files-layout.md" . }}

{{ includeTemplate "config/ai/workflows/ai/includes/memory-behavior.md" . }}
