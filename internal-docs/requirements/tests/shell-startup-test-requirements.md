# Shell Startup Test Requirements

The `scripts/tests/test-in-container.bash` script must be updated to enhance the validation of the shell startup environment for test users within the devcontainer.

## Test Validation Requirements

The script must perform the following checks after a test user's shell is initialized:

### 1. `STARTUP_TEST_ENV` Directory Loading

The test must inspect the `STARTUP_TEST_ENV` environment variable to ensure the correct configuration directories are being sourced based on the user's shell (Bash or Zsh).

-   **Zsh Test (`testuser-zsh`)**:
    -   **Must Include**: Paths containing `.config/shells/zsh/{env,utils,aliases,prompts}`.
    -   **Must Include**: Paths containing `.config/shells/shared/{env,utils,aliases,prompts}`.
    -   **Must NOT Include**: Any path containing `.config/shells/bash/`.

-   **Bash Test (`testuser-bash`)**:
    -   **Must Include**: Paths containing `.config/shells/bash/{env,utils,aliases,prompts}`.
    -   **Must Include**: Paths containing `.config/shells/shared/{env,utils,aliases,prompts}`.
    -   **Must NOT Include**: Any path containing `.config/shells/zsh/`.

### 2. Critical Environment Variables

The test must verify that the following environment variables are correctly set after shell initialization:

-   `BUN_INSTALL`: The variable must be set and not empty.
-   `PATH`: The variable must contain the path to the mise shims directory, which is expected at `/home/<test-user>/.local/share/mise/shims` (e.g., `/home/testuser-zsh/.local/share/mise/shims`).

## Implementation

-   If any of these conditions are not met, the test script must fail with a non-zero exit code.
-   The underlying issue causing a potential failure should be fixed in the devcontainer setup script (`.devcontainer/setup.sh`) to ensure the tests pass. This involves correctly exporting `BUN_INSTALL` and adding the `mise` shims directory to the `PATH`.
