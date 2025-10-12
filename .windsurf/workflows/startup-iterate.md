---
description: Iterate through startup issues
auto_execution_mode: 3
---

Iterate over this loop until startup tests are all successful

1. commit any changes that need to be committed, don't ask to commit, just compose a good message and commit (without running tests again, as chezmoi needs fiels committed to use them, and you would only test old files otherwise)
2. use `rm -rf ~/.cache/dotfiles; scripts/tests/test-in-container2.bash && ~/.local/bin/chezmoi purge --force && ~/.local/bin/chezmoi init . && ~/.local/bin/chezmoi apply --dry-run && ~/.local/bin/chezmoi apply --dry-run && ~/.local/bin/chezmoi apply`
3. if any of the tests fail, fix the issue
4. repeat

## Notes:
The intention is that all the appropriate directories are loaded as listed in $STARTUP_TEST_ENV and no inappropriate directories as loaded. This list is maintained and tested in the function `@test "entrypoint STARTUP_TEST_ENV enumerates directory tokens"` in the file `scripts/tests/entrypointrc-file-listing.bats` that is called via `scripts/tests/test-in-container.bash`
