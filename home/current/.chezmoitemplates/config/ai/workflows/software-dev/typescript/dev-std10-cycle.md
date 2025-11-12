---
description: After making a change, this is the iterative process
---

## Reminder
- If it's Node, we're probably using `pnpm` pay attention to the lockfiles.
- Run all interactions as `non-interactive`
- Do NOT sacrifice type safety to hide lint issues!

## Iterative
1. Run `lint` if it hasn't been run yet. If it has installation problems on this host, skip it from now until I say otherwise.
2. If only `Mock` related issues were there, then move forward, otherwise, fix the issues, and try again
3. run `test` and `coverage` if it hasn't been run yet. If it has installation problems on this host, skip it from now until I say otherwise.
4. If all tests were successful, move forward. otherwise fix, and go back to `lint` step again.
5. run `build` if it hasn't been run yet. If it has installation problems on this host, skip it from now until I say otherwise.
6. If `build` was successful, move forward. otherwise fix, and go back to `lint` step again.
7. run /chore-ai20-vcs for only ONE commit. No more.
8. Make sure all necessary build artificats are in the right place.
9. Give a summary of the changes, the quantified results of lint, test, coverage, and build. List the branch name.
