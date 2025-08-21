---
description: Commit the changesets to VCS
---

# Version Control System Workflow

This workflow provides guidelines for managing changes in your version control system.

## Preparing Changes

1. Check status of your working directory:
```bash
git status
```

2. Stage changes for commit:
```bash
git add <files>
```

3. Review staged changes:
```bash
git diff --staged
```

## Committing Changes

1. Create a commit with a descriptive message:
```bash
git commit -m "type(scope): description"
```

2. Follow conventional commit format:
   - feat: A new feature
   - fix: A bug fix
   - docs: Documentation only changes
   - style: Changes that do not affect the meaning of the code
   - refactor: A code change that neither fixes a bug nor adds a feature
   - perf: A code change that improves performance
   - test: Adding missing tests or correcting existing tests
   - chore: Changes to the build process or auxiliary tools

## Pushing Changes

1. Update your local branch with remote changes:
```bash
git pull --rebase origin <branch>
```

2. Push your changes to the remote repository:
// turbo
```bash
git push origin <branch>
```

## Creating Pull Requests

1. Create a pull request from your branch to the target branch
2. Add a descriptive title and detailed description
3. Request reviews from appropriate team members
4. Address feedback and make necessary changes
