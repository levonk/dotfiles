---
title: "AI Code Documenter"
template: 'AI Coding Prompt Pattern'
slug: 'ai-pattern-coding-docstrings'
description: 'Analyzes a provided multi-language codebase and generates comprehensive, high-quality docstrings for all specified components based on a set of rules.'
use: 'When needing to document a new or existing codebase with a consistent, standard format across multiple programming languages.'
version: 2.0.0
owner: 'https://github.com/levonk'
status: 'ready'
date:
  created: '2025-11-24'
  updated: '2025-11-25'
tags:
  - 'ai/template/prompt/pattern/coding'
  - 'documentation'
  - 'docstrings'
  - 'multi-language'
---

## <objective>
Your objective is to act as an expert Senior Software Engineer and generate comprehensive, accurate, and consistently formatted docstrings for the provided multi-language codebase. The goal is to make the code more readable, maintainable, and easier for new developers to understand.
</objective>

## <context>
You are documenting a codebase that contains multiple programming languages. Adhering to professional and consistent documentation standards is critical. The generated docstrings will be used by developers and automated tools (like Sphinx, JSDoc) to create documentation.

If the user:
- provides no explicit files, process the entirety of the current repository
- provies a glob, process the glob pattern
- provides a subdirectory traverse the tree for files, or process the files only in that specific directory if the user explicitly says to not recurse.

**Documentation Standards:**
You are to apply the following rules to determine which docstring format to use for each file.
- **Python (`.py`):** Google Style
- **TypeScript/JavaScript (`.ts`, `.js`, `.tsx`, `.jsx`):** TSDoc
- **Java (`.java`):** Javadoc
- ***Default Fallback:*** If a file's language is not listed in the rules, use the most common and conventional docstring/comment block format for that language.

- **Specs / ADRs / docs:**
  - PEP 257 – Docstring Conventions: (Python)
  - TSDoc Standard: https://tsdoc.org/ (TypeScript)
  - JSDoc Home: https://jsdoc.app/ (JavaScript)
</context>

## <requirements>
1.  **Determine Language:** For each file, first determine its programming language based on its file extension and content.
2.  **Select Docstring Format:** Based on the determined language, select the appropriate docstring format using the rules defined in the `<context>` block.
3.  **Generate Docstrings:** For every codebase, package, file, module, interface, enum, class, data member, sql query, constant, function, and method, generate a high-quality docstring that strictly adheres to the selected format.
4.  **Comprehensive Content:** Ensure each docstring includes, where applicable: a one-line summary, a detailed description, descriptions of all arguments/parameters (including inferred types), and a description of the return value(s) and any exceptions raised.
5. **Proper References:** Use proper referencing formats for links to callers, interfaces, implementations, dependencies, etc...
6.  **Idempotency:** If a file already has a correctly formatted docstring for an object, you may leave it as-is or make minor corrections. Replace placeholder or incomplete docstrings.
</requirements>

## <documentation_philosophy>
Good documentation explains the **"why,"** not just the **"how."** The code itself shows *how* an operation is performed, but the docstring must explain *why* it exists and its role in the system. When generating docstrings, adhere to these principles:

1.  **Describe Intent:** Focus on the purpose of the code.
    *   **Bad:** *"This function loops through the users and increments the 'attempts' field."* (This is just a description of the code.)
    *   **Good:** *"This function tracks a user's login attempts. It should be called after a failed authentication to support account lockout policies."* (This explains the business logic and context.)

2.  **Write for a New Developer:** Assume the reader is intelligent but unfamiliar with this specific codebase. Avoid project-specific jargon without explanation. Your goal is to make their onboarding process faster.

3.  **Explain Non-Obvious Behavior:** If a function has important side effects, makes assumptions about its inputs, or contains a non-obvious piece of logic due to a business requirement, explain it clearly.

4.  **Provide Examples (If Complex):** For functions with complex parameters or a non-trivial setup, include a short, clear usage example within the docstring.
</documentation_philosophy>

## <implementation>
- Process the files in the order they were provided.
- If the file is under version control, update it in place. If it is not, move the old one to a `*.bak` renamed version.
- Pay close attention to indentation and syntax to ensure the new docstrings are correctly placed and the code remains valid.
- subsequent to changes, run any documentation lint that the repository is already configured for, or strict lint tools, (like `pydocstyle` for Python).
</implementation>

## <output>
Besides updating the existing files, or renaming the old one and replacing them.

Present the updated code for each file separately and incrementally as you are processing. Use a clear header to indicate which file's content is being shown, along with the language and the following fields lines added `+`, lines changed `~`, lines unchanged `.`, lines deleted `-`

Add a final line for the totals.

Example Summary Output Structure:
```text
- ./src/server/main.py / Python: +25 added | ~10 changed | .0 unchanged | -1 deleted
- ...
- Totals: +25 added | ~10 changed | .0 unchanged | -1 deleted
```
</output>

## <verification>
Before declaring the task complete, perform a final review to ensure:
1.  Every module, file, public function, member, method, and class in the provided files has a docstring.
2.  The format of each docstring correctly matches the rules specified in the context.
3.  The code in the output is syntactically correct and includes the complete original source.
</verification>

## <success_criteria>
The task is successful when all provided code files have been updated with complete, accurate, and consistently formatted docstrings according to the specified language-to-format rules.
</success_criteria>
