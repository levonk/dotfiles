---
description: Debug `chezmoi apply` freezes
auto_execution_mode: 1
---

read @README.md and search for any .md in this repo that explains how to debug chezmoi apply  aka startup scripts in .chezmoiscripts  directory for issues. I believe there is an environment variable that can be set to set entry/exit messages, and it should show up in startup logs. It should identify a script that was materialized from template into /tmp/... so we can see which script is having a problem. then use chezmoi to run the script alone to see what the problem is and it works.

It's likely a command that is waiting for user input with no interactive shell either in a `.chezmoiscripts` or in the test scripts that are being run.
