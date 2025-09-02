# Architecture Decision Records (ADR)

## Overview
When working on software projects, document significant architectural decisions using Architecture Decision Records (ADRs). These are short text files that capture the context, decision, and consequences of important architectural choices.

## Rules for Creating and Managing ADRs

### When to Create an ADR
- Create an ADR for any "architecturally significant" decision that affects:
  - System structure
  - Non-functional characteristics
  - Dependencies
  - Interfaces
  - Construction techniques
  - Technology choices
  - Framework selections
  - Pattern implementations

### ADR Format
Each ADR should follow this structure:

```markdown
# ADR-NNN: Title (Short Noun Phrase)

## Status
[Proposed | Accepted | Deprecated | Superseded by [ADR-XXX](link-to-adr)]

## Context
[Describe the forces at play, including technological, political, social, and project-specific concerns. Be value-neutral and factual.]

## Decision
[Describe the decision made in full sentences with active voice: "We will..."]

## Consequences
[Describe all consequences - positive, negative, and neutral - that result from this decision.]
```

### ADR Management Guidelines
1. Store ADRs in the project repository under `internal-docs/architecture/decisions/`
2. Name files as `adr-NNN-title-with-hyphens.md` where NNN is a sequential number
3. Numbers are sequential, monotonic, and never reused
4. If a decision is reversed, keep the old ADR but mark it as "Superseded"
5. Link superseded ADRs to their replacement
6. Keep each ADR document concise (1-2 pages)
7. Write in full sentences organized into paragraphs
8. Write as if having a conversation with a future developer

### Implementation Process
1. When starting a new project, initialize the ADR directory:
   ```
   mkdir -p internal-docs/architecture/decisions
   ```

2. Create the first ADR explaining the decision to use ADRs:
   ```
   # ADR-001: Use Architecture Decision Records

   ## Status
   Accepted

   ## Context
   [Context about why documentation is needed]

   ## Decision
   We will use Architecture Decision Records to document significant architectural decisions.

   ## Consequences
   [Consequences of using ADRs]
   ```

3. For each new architectural decision:
   - Create a new numbered ADR file
   - Fill in all sections
   - Review with team members
   - Update status when accepted

## Integration with Development Workflow
- Review existing ADRs before making changes that might conflict with prior decisions
- Reference ADRs in code comments, pull requests, and technical documentation
- Update ADRs when decisions change
- Include ADR reviews in architectural discussions

<!-- 
IMPLEMENTATION DECISION COMMENT:

This rules file implements a lightweight ADR process that balances formality with practicality. While the adr-tools (https://github.com/npryce/adr-tools) provides CLI tooling for managing ADRs, this implementation focuses on the core concepts and practices without requiring external tools.

Reasons for this approach:
1. Tool Independence: Not requiring external tools makes adoption easier across different environments and teams
2. Focus on Content: Emphasizes the importance of the decision record content rather than the tooling
3. Flexibility: Teams can adopt the process without installing additional software
4. Simplicity: Reduces the learning curve for new team members

Teams that find themselves creating many ADRs may benefit from adopting adr-tools later, but starting with this manual approach ensures focus on the value of decision documentation rather than the mechanics of tool usage.

The format closely follows [Michael Nygard's original proposal](https://cognitect.com/blog/2011/11/15/documenting-architecture-decisions) while providing clear guidelines on when and how to create ADRs, making it accessible for teams new to the practice.
-->
