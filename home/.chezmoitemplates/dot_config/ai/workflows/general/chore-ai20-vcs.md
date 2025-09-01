---
description: Handle unadded/uncommitted files in repository
auto_execution_mode: 1
---

## Steps

1. Make sure all editor buffers have been saved, and the editor sees exactly whats on disk.
2. Do a `git status --untracked-files=all --porcelain` in the current directory, OR the directory I tell you to use. Do not rely on your internal index. I'm not interested in just checking in the last thing you worked on, I'm asking you to get me to a repository with no untracked or uncommitted files.
3. Look at the files within all repositories that have been changed and not committed OR that are new to the project.
4. run any linter, formatter, and finally unit tests that are available on the system, if not stop trying to run that tool.
5. if the user is configured to sign commits, don't forget to sign the commit when doing it. If not don't try signing again, and repeat.
6. Understand the changes, and try to group them in unique changesets that make sense so multiple changes get multiple commits. e.g. changes to login page, and it's associated confg, documentation, typescript, css, dependency listing changes, test code, is all one commit, and changes to settings page and it's associated database files, css, typescript, test code, is all ONE different commit.
7. Title each commit with the following
  a. a short prefix to identify the type of change e.g. is it a feat[ure], fix, new, doc, test, chore, refactor
  b. a hyphen to separate the the type, from the scope which follows
  c. a short name that represents scope of the change. e.g. feat-build, fix-login, etc..
  d. a colon followed by a space, an a short synopsis of the change
  e. the title should be no longer that 50 characters. Use contractions, and other tricks to shorten the title to below <50 characters. An example would be `feat(search): added filters for user`
8. A body that explains the change in more detail, wrapped at 72 characters per line
9. A footer that references any bug base tickets, story IDs
10. summarize what you did, and if anything needs the USER's attention.

## Guidelines

- Use the imperitive mood: "Add checkbox" not "Added checkbox"
- Group the changes by functionality, not file types. i.e. dont make a commit labeled "code files", and another named "test files", but commits by user facing functionality like "login page", and "settings page" which cuts across file types.
- if you're in windows, and `wsl` is installed, use `wsl` to do your git commands.
- Be specific: "fix overflow in sidebar menu" is better than "fix bug"
- Explain the why: Not just what changed, but why it was needed.
- Avoid filler Skip vague phrases like "oops" or "maybe fixed"
- Capitalize the subject and omit punctuation
- Avoid commiting half done work
- Scan for any secrets or private information before committing; if any are found, stop and notify the user immediately.
- If you aren't 96% confident you understand the change, ask for clarification.
- Always use LF for commit messages, NOT CRLF
- DO NOT `git push`, unless specifically asked to


11. After all commits are processed, do the git status again, to verify there are no untracked, modified, or uncommitted files. If there are repeat the process starting from step 0. 

12. Do a `git log --stat` for the new commits 

13. summarize how many commits you made, how many files totoal, and avg, min, max number of files. Then list comments need the USER's attention.