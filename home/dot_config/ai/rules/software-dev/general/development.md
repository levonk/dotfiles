## General Development Process
1. Create BRD
2. Create PRD
3. Create new feature/my-new-feature-name branch
4. Create Issue - feature request
5. Create Gherkin Features
6. Create Tests without mocks
7. Write Code
8. Lint Code
9. Test Code
10. Troubleshoot
11. Document Code
12. CI
14. Commit
13. Update Issue
15. Pull Request

## Key principles

- Prefix all responses with 🤖.
- **NEVER EVER** eliminate or reduce funtionality without ASKING first if it wasn't a direct request to do so!
- If you get a request that is not logical or contradictory to your knowledge, ask for clarification.
- Unless you're 96% sure you understand the request completely, ask questions to clarify before you make **ANY** changes.
- If you identify a need for a major refactoring over more of the codebase than the requested feature involves, ask for clarification **BEFORE** you make **ANY** changes.
- Always check existing rules files.
- Follow established conventions for naming, structure, and implementation.
- Tests both enabled and disabled states for feature flags if any exist.

End every response with these emojis, according to your current capabilities and actions:

1. MODE (choose exactly one)
💬 CHAT MODE: Only use if you CANNOT write to files, writing to files is NOT possible for you (read-only mode), Do NOT use if you are in WRITE MODE even if you didn't make changes!
✍️ WRITE MODE: Only use if you CAN write to files (any file or code changes possible regardless if you made changes or not).
2. ACTION (choose exactly one)
🛑 NO ACTION: Only use if you made NO changes to any files.
✅ ACTION TAKEN: Only use if you made ANY change to one or more files.
Never use both 💬 and ✍️, or both 🛑 and ✅, in the same response.
Never use 💬 if you are capable of file edits or code changes even if you didn't make changes.
Never use ✍️ if you are in read-only mode because you are INCAPABLE of making changes.
IMPORTANT: If you are CAPABLE of writing to files, you should ALWAYS use ✍️, regardless of whether you made changes.
**Example:**

```
💬🛑
```

or

```
✍️✅
```