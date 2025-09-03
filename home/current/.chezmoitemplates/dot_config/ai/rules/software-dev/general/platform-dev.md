---
description: Host platform guidelines across Windows, Linux, and macOS
---

# Host Platform Guidelines

- Determine the host platform that you're operating on and act appropriately.
- Always quote paths containing spaces (e.g., "C:\\My Project\\file.ts").

## Windows 11+

- PowerShell (pwsh) is the likely terminal. All commands and scripts must be compatible.
- Pathing: Use single backslashes (`\\`) in file paths and forward slashes (`/`) in URLs.
- In Node.js contexts, always use `path.win32.join()` or `path.win32.resolve()` to construct paths; never hardcode path separators.
- No Linux Commands: Do NOT use `bash`, `sudo`, `apt`, `brew`, or common Linux utilities (`sed`, `awk`, `grep`).
- Use PWSH Equivalents: `rm` → `Remove-Item`, `mv` → `Move-Item`, `cp` → `Copy-Item`, `ls` → `Get-ChildItem`, `cat` → `Get-Content`, `touch` → `New-Item -ItemType File`, `grep` → `Select-String`.
- Environment Variables: Access with `$env:VAR_NAME`; set with `$env:VAR_NAME = "value"`.
- File Output: Prefer `Out-File` or `Set-Content` over shell redirects (`>`) for better encoding control.

## Linux

- The terminal preference is Zsh but it may be Bash. All commands and scripts must be compatible, but the preference is they are written for Bash.
- Pathing: Use forward slashes (`/`) in file paths and forward slashes (`/`) in URLs.
- In Node.js contexts, always use `path.posix.join()` or `path.posix.resolve()` to construct paths; never hardcode path separators.

## macOS

- Zsh is the terminal. All commands and scripts must be compatible, but the preference is that they are written for Bash.
- Pathing: Use forward slashes (`/`) in file paths and forward slashes (`/`) in URLs.
- In Node.js contexts, always use `path.posix.join()` or `path.posix.resolve()` to construct paths; never hardcode path separators.
