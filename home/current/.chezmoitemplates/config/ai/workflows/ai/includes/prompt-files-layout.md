## PROMPT FILES LAYOUT

Prompt-related files live under `./internal-docs/prompts/`.

### Prompt filename pattern

Prompt files in the prompt directories follow this pattern:

```text
./internal-docs/prompts/<state>/<project-slug>-prompt-<YYYYMMDDHHMM>-<step>-<parallel>-<prompt-slug>.md
```

- `<state>`: `todo`, `processing`, `rework`, or `completed`.
- `<project-slug>`: short identifier for the project or domain (for example, `resume`, `dns-chain`).
- `<YYYYMMDDHHMM>`: timestamp when the prompt was created.
- `<step>`: zero-padded **sequential phase number** (for example, `01`, `02`).
- `<parallel>`: zero-padded **parallel prompt index** within that phase (for example, `01`, `02`).
- `<prompt-slug>`: short, kebab-cased description of the prompt (for example, `gather-job-history`).

#### Sequential vs. parallel semantics

- Prompts with the **same** `<step>` and different `<parallel>` values are **parallel-capable** within that phase.
- Prompts with **increasing** `<step>` values represent **dependent phases** that should be handled in order.

Example:

```text
./internal-docs/prompts/todo/resume-prompt-2025111423-01-01-gather-job-history.md
./internal-docs/prompts/todo/dns-chain-prompt-202511150930-02-01-configure-dnsdist.md
./internal-docs/prompts/todo/dns-chain-prompt-202511150930-02-02-configure-coredns.md
```

In this example, the two `dns-chain` prompts at step `02` can be run in parallel, but only after any step `01` prompts for that series have been completed.
