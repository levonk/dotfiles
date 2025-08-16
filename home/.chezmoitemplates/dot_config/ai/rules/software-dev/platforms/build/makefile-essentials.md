# Make & Makefiles

Here's a generalized set of guidelines and best practices for structuring Makefiles in software projects. These are designed to promote maintainability, readability, and consistency across all your projects.

## Core Principles

*   **Centralized Scripting:**  All non-.PHONY executable logic resides in scripts within a designated `/bin` directory (or a similar dedicated directory structure for scripts). This is not necessary for things like help/usage. The `Makefile` primarily orchestrates these scripts, managing dependencies and sequencing.
*   **Makefile as Orchestrator:** The `Makefile` *only* handles dependency management and the *order* of execution. Avoid complex shell scripting *within* the Makefile.
*   **Standardized Targets:**  Every `Makefile` across all projects *must* implement a common set of targets.
*   **Documentation-Driven:**  Every target in a `Makefile` *must* be documented in the project's `README.md` file and the `help` target.
*   **Be Informative:**  Consistent logging with [TAG] prefixes.
*   **Copier-Friendly:**  The boilerplate Makefiles should be designed to work seamlessly with `copier` for easy project creation and updates.
*   **DRY (Don't Repeat Yourself):**  Maximize code reuse and avoid duplication through variables, functions, and included files.
*   **Graceful Failure:**  Make targets should fail gracefully, providing informative error messages and avoiding unintentional side effects.
*   **Makefiles until Module level:**  For every step down the tree of the project there should be a Makefile down to the module level. Calling `make` at the module level will operate solely on the module. Calling `make` at the collection or library level will solely operate on the library and all of it's children modules. Calling `make` on the application level will operate on the app, all it's libraries in the same repo, and all of the modules that are relied on in the same repo.

## Makefile Targets

### Mandatory Makefile Targets

The following targets *must* be present in every `Makefile` and execute corresponding scripts in the `/bin` directory:

*   **`clean`:**  Removes generated files (object files, executables, temporary files, etc.).
*   **`archive`:** Creates an archive of the project (e.g., a `7z` file).  This assumes the existence of an archiving script in `/bin`.
*   **`all`:** Builds the entire project.  This is often the default target, but can also be used for a specific configuration, defaulting to dev (development).
*   **`help` aka `usage`:** Displays a list of available targets with brief descriptions.  (See auto-generation details below).
*   **`check`:** Runs static analysis tools and other checks to ensure code quality and consistency.
*   **`format`:**  Formats the code according to project coding standards.
*   **`test`:**  Runs all unit tests.
*   **`lint`:**  Runs all linting tools to identify potential code issues. There should be individual targets for each type of lint that the main 
    *  **lint-markdown:** Linting for `*.md` documentation and files.
*   **`coverage`:** Generates code coverage reports.
*   **`version`:** Displays the current project version.
*   **`status`:** Shows the current status of the project (e.g., Git branch, commit hash, build status).
*   **`watch`:**  Monitors files for changes and automatically rebuilds or reruns tests.
*   **`env`:** Sets up or displays the project's development environment.
*   **`docs`:**  Regenerates documentation from source code.
*   **`sync`:** Performs a Git rebase to synchronize the local branch with the remote.

### Preferred Makefile Targets

These targets may ALSO be aliased versions of targets that are specific to the project.

*   **`promote`:** Updates the build number for the next build.
*   **`new-module`:** Creates a new module or component within the project.  (Requires a well-defined directory structure).
*   **`run`:**  Executes the compiled program or application.
*   **`install`:**  Installs the project to a system directory.
*   **`uninstall`:** Removes the installed project from the system.
*   **`deploy`:** Deploys the project to a specified environment.  Should have variants for `dev` (default) and `prod`.  Example: `deploy-dev`, `deploy-prod`.

### Potential Targets

*   **`mutation`:** Performs mutation testing.
*   **`performance`:** Performs performance testing.
*   **`security`:** Performs security checks.
*   **`docker`:** builds release into docker package. This may be the standard build or release procedure if there isn't a compile step.
*   **`docker-run`:** runs a `docker-compose` or `docker run` for the generated package.
*  **`lint-make`:** Linting for `Makefiles` using multiple linters. This target runs:
    * **`lint-make-checkmake`:** Uses [checkmake](https://github.com/checkmake/checkmake) to lint Makefiles for common errors and best practices.
    * **`lint-make-bake`:** Uses [bake](https://github.com/EbodShojaei/bake) to check Makefile structure and patterns.
*  **`lint-ansible`:** Only if Ansible collections exist for the project.
*  **`lint-yaml`:** Only if yaml files exist for the project.

## Directory Structure and Script Location

*   **Scripts Directory:** All executable scripts *must* reside in a central `/bin` directory or a well-defined subdirectory structure within it (e.g., `/bin/format`, `/bin/test`, `/bin/deploy`).  *Do not* create scripts anywhere else!
*   **Makefile Location:**  Place `Makefiles` in appropriate directories based on the project's module/component structure. This facilitates modular builds and testing.
*   **Copier Templates:** Keep your copier template (e.g., in `${REPO_ROOT}/ansible-galaxy/collections/ansible_collections/blueprint-namespace/blueprint-collection/`) up-to-date with these new best practices.

## Makefile Best Practices & Style

*   **`.PHONY` Targets:**  Declare all non-file targets (like `clean`, `help`) as `.PHONY`.
    ```makefile
    .PHONY: clean archive all help check format test lint run install uninstall coverage deploy release version status watch env docs sync new-module deploy-dev deploy-prod
    ```

*   **`.DEFAULT_GOAL`:** Set a default goal (usually `help` or `all`) so that running `make` without arguments performs a useful action. Whatever the default is, in the case of it being a default run of `make` with no arguments, it should follow calling `help` and explaining which target is being called subsequently.
    ```makefile
    .DEFAULT_GOAL := help
    ```

*   **Logical Grouping:** Organize targets into logical groups (e.g., build, testing, deployment) using comments and headers.

*   **Explicit Rules:** Avoid relying on implicit rules unless you fully understand their behavior.  Be explicit about dependencies and commands.

*   **Variables:** Use variables to avoid repetition and make the `Makefile` easier to maintain.

    ```makefile
    PROJECT_NAME := my-awesome-project
    BIN_DIR      := /bin
    FORMAT_SCRIPT := $(BIN_DIR)/format

    format:
    	$(FORMAT_SCRIPT)
    ```

*   **Shell Functions (Judiciously):**  Define shell functions for more complex, reusable logic, but *still* prefer calling external scripts.

    ```makefile
    # Example (use sparingly - prefer scripts)
    define get_git_commit
    	$(shell git rev-parse HEAD)
    endef

    GIT_COMMIT := $(call get_git_commit)
    ```

*   **Modular Makefiles (using `include`):**  For large projects, break the `Makefile` into smaller, modular files and `include` them.  This improves organization and reduces complexity.

    ```makefile
    include modules/database.mk
    include modules/frontend.mk
    ```

*   **Error Handling:**  Add error handling to targets to ensure they fail gracefully.
    ```makefile
    validate:
    	@$(BIN_DIR)/validation-script || (echo "Validation failed!" && exit 1)
    ```

*   **Parallel Execution:**  Ensure targets are safe for parallel execution using `make -j`.  Declare dependencies correctly to avoid race conditions.

*   **Auto-Generated `help` Target:** Implement a `help` (and have a `usage` alias) target that automatically extracts target descriptions from the `Makefile`.

    ```makefile
    help: ## Show this help message
    	@grep -E '^[a-zA-Z_-]+:.*?## ' Makefile | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
    ```

    *   **Important:** Use `##` after the target definition to add the description.

    ```makefile
    clean: ## Remove generated files
    	$(BIN_DIR)/clean
    ```

*   **Informative Comments:**  Add comments to explain the *why* behind decisions, not just the *what*.

*   **Environment Detection:**  Create targets to check the environment and tool versions.  Be sure to include all tools called from the scripts in `/bin`. This helps ensure that the project can be built and run correctly.

    ```makefile
    env-check:
    	@echo "Checking Python version..."
    	@python3 --version
    	@echo "Checking required dependencies..."
    	@pip3 freeze | grep -q "requests" || (echo "Error: requests library not found. Please install it." && exit 1)
    ```

*   **Documentation Synchronization:**  Automate a check or a target to ensure that the `README.md` documentation matches the `Makefile` targets and includes a `mermaid` diagram that includes the dependency tree.

*   **Sentinel Files/Metadata:**  Use sentinel files or metadata files (e.g., `.ruleset`, `.windconf`) to encode configuration or dependencies for each component or directory.

## Example Makefile Structure

```makefile
# ====================================================================
# Project Configuration
# ====================================================================

PROJECT_NAME := my-amazing-application
BIN_DIR      := /bin
VERSION      := 1.2.3

# ====================================================================
# Phony Targets (Targets that don't create files)
# ====================================================================

.PHONY: clean archive all help check format test lint run install uninstall coverage deploy release version status watch env docs sync new-module deploy-dev deploy-prod

.DEFAULT_GOAL := help

# ====================================================================
# `all` Target
# ====================================================================

all: ## Build the entire project
	$(BIN_DIR)/build

# ====================================================================
# Cleaning Targets
# ====================================================================

clean: ## Remove generated files
	$(BIN_DIR)/clean

archive: ## Create an archive of the project
	$(BIN_DIR)/archive

# ====================================================================
# Testing Targets
# ====================================================================

test: ## Run all unit tests
	$(BIN_DIR)/test

lint: lint-make ## Run all linting tools
	$(BIN_DIR)/lint

# ====================================================================
# Linting Targets
# ====================================================================

lint-make: lint-make-checkmake lint-make-bake ## Run all Makefile linters

lint-make-checkmake: ## Run checkmake on Makefiles
	@if command -v checkmake >/dev/null 2>&1; then \
		echo "Running checkmake..."; \
		find . -name 'Makefile' -o -name '*.mk' | xargs -n1 checkmake; \
	else \
		echo "checkmake not installed. Install with: go install github.com/checkmake/parser@latest && go install github.com/checkmake/checkmake@latest"; \
		exit 1; \
	fi

lint-make-bake: ## Run bake on Makefiles
	@if command -v bake >/dev/null 2>&1; then \
		echo "Running bake..."; \
		find . -name 'Makefile' -o -name '*.mk' | xargs -n1 bake check; \
	else \
		echo "bake not installed. Install with: go install github.com/EbodShojaei/bake@latest"; \
		exit 1; \
	fi

check: ## Run static analysis and code checks
	$(BIN_DIR)/check

coverage: ## Generate code coverage reports
	$(BIN_DIR)/coverage

# ====================================================================
# Formatting Targets
# ====================================================================

format: ## Format code according to standards
	$(BIN_DIR)/format

# ====================================================================
# Running and Installation Targets
# ====================================================================

run: ## Execute the application
	$(BIN_DIR)/run

install: ## Install the application
	$(BIN_DIR)/install

uninstall: ## Uninstall the application
	$(BIN_DIR)/uninstall

# ====================================================================
# Deployment Targets
# ====================================================================

deploy-dev: ## Deploy to the development environment
	$(BIN_DIR)/deploy dev

deploy-prod: ## Deploy to the production environment
	$(BIN_DIR)/deploy prod

deploy: deploy-dev ## Default deploy target is development

# ====================================================================
# Release Targets
# ====================================================================

release: ## Create a release package
	$(BIN_DIR)/release

version: ## Display the project version
	$(BIN_DIR)/version

status: ## Show the project status (git, build, etc.)
	$(BIN_DIR)/status

# ====================================================================
# Development Targets
# ====================================================================

watch: ## Monitor files for changes and rebuild
	$(BIN_DIR)/watch

env: ## Set up the development environment
	$(BIN_DIR)/env

docs: ## Regenerate documentation from source
	$(BIN_DIR)/docs

sync: ## Sync with the remote repository (git rebase)
	$(BIN_DIR)/sync

new-module: ## Create a new module or component
	$(BIN_DIR)/new-module

# ====================================================================
# Help Target
# ====================================================================

help: ## Show this help message
	@grep -E '^[a-zA-Z_-]+:.*?## ' Makefile | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
```

## Updating Copier Templates

1.  **Modify Existing Templates:** Update the base Makefiles in your `copier` templates (e.g., `/blueprint-namespace/blueprint-collection/Makefile`) to include the standard targets, the `.PHONY` declarations, and the `help` target generation.
2.  **Automate Documentation Updates:**  Consider adding a `post_gen_project.py` script to your `copier` template that automatically creates or updates the `README.md` with a list of Makefile targets, extracted from the generated `Makefile`. This will help ensure the `README.md` remains synchronized.  This could look like:

```python
# in post_gen_project.py
import re
import os

def update_readme():
    makefile_path = 'Makefile'
    readme_path = 'README.md'
    target_regex = re.compile(r'^([a-zA-Z_-]+):\s.*?##\s(.*)$', re.MULTILINE)

    with open(makefile_path, 'r') as f:
        makefile_content = f.read()

    targets = target_regex.findall(makefile_content)

    readme_content = f"""
# {{ "{{" }} project_name {{ "}}" }}

Description of the project.

## Available Make Targets

| Target      | Description                                  |
|-------------|----------------------------------------------|
"""
    for target, description in targets:
        readme_content += f"| `{target}`    | {description} |\n"

    with open(readme_path, 'w') as f:
        f.write(readme_content)

if __name__ == "__main__":
    update_readme()
```

## Enforcement and Continuous Improvement

*   **Code Reviews:** Enforce these guidelines through code reviews.
*   **Linting:**  Consider writing a simple linter or script to check for common Makefile errors (e.g., missing `.PHONY` declarations, missing target documentation).
*   **Iteration:**  These guidelines are a starting point.  Continuously refine them based on your experience and the needs of your projects.