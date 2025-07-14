# Commit Message Template
<!-- detailed explanation at the end of the template and at https://www.conventionalcommits.org/ -->

<!--
|<----  Using a Maximum Of 50 Characters  ---->|
  1.  Summary (50 characters max, including type prefix):
         - Be concise and descriptive.
         - Start with [COMMIT-TYPE] from the list below
         - The summary should be a single line.
         - Keep lines to 50 characters or less.
         - Use imperative mood ("Add feature" instead of "Adding feature").
         - like GitHub. Imperative mood conveys the action taken.
         - Reference issue numbers if applicable (e.g., "Fix bug #123").
         - **Reason:** Limits ensure readability in Git logs and on platforms
         - There should be one blank line following the summary

|<---------------  Using a Maximum Of 72 Characters  --------------->|
  2.  Body (Optional):
         - Provide more context and details about the change.
         - Explain *why* the change was made and the problem it solves.
         - Use multiple paragraphs if necessary.
         - Keep lines to 72 characters or less.
         - **Reason:**  The body provides essential context that the summary
           cannot. Explaining the *why* is often more important than the *what*.
         - There should be one blank line following the body

  3.  Footer (Optional):
         - Breaking Changes: If the commit introduces a breaking change,
           describe it in detail. This is crucial for communicating
           the impact to other developers.
         - References:  Link to related documentation, discussions, or external
           resources.
         - Closes: #issue-number (automatically closes the issue on merge
           in some platforms like GitHub).
         - **Reason:** The footer provides additional metadata, such as
           breaking change notices and links to related resources, enhancing
           the commit's overall value.

  ---
  COMMIT TYPES:
  - feat:      A new feature
  - fix:       A bug fix
  - docs:      Documentation changes
  - style:     Changes that do not affect the meaning of the code (white-space, formatting, missing semi-colons, etc)
  - refactor:  A code change that neither adds a feature nor fixes a bug
  - perf:      A code change that improves performance
  - test:      Adding missing tests or correcting existing tests
  - build:     Changes that affect the build system or external dependencies (example scopes: gulp, broccoli, npm)
  - ci:        Changes to our CI configuration files and scripts (example scopes: Travis, Circle, BrowserStack, SauceLabs)
  - chore:     Other changes that don't modify src or test files
  - revert:    Reverts a previous commit
  -->

## Type: Subject

<!--
  - Choose a commit type from the list above (e.g., `feat`, `fix`, `docs`, etc.).
  - Use a single, clear subject line.
  - **Reason:** Commit types categorize the nature of the change, aiding
    in filtering and automated tasks. Clear subject lines provide a
    concise overview.
-->

## Body

<!--
  - Elaborate on the changes made in this commit.
  - Explain the reasoning behind the changes.
  - Provide context for reviewers.
  - Use Markdown formatting for readability.
  - **Reason:** The body expands on the subject, providing deeper insight
    into the commit's purpose and implementation details.
-->

## Footer

<!--
  - Breaking Changes:  Describe any breaking changes introduced by this commit.
     BREAKING CHANGE: [Description of the breaking change and its impact]

  - Closes: #issue-number (Closes the specified issue on merge)
  - Refs: #issue-number, https://example.com/docs (Links to related resources)
  - **Reason:** The footer provides essential metadata, such as breaking change notices and references to related issues or documentation.
-->

<!--
  This template is designed to encourage well-formatted and informative commit
  messages, based on best practices and conventional commits.  It aims to:

  1.  **Improve Communication:** Make it easier for developers to understand
      the history of the project and the reasoning behind changes.
         - **Reason:** Clear and consistent commit messages facilitate
           collaboration, debugging, and maintenance.
  2.  **Standardize Commit History:** Ensure a consistent format for all commit
      messages.
         - **Reason:** A standardized history simplifies searching, filtering,
           and generating release notes or changelogs.
  3.  **Enable Automation:** Allow for automated tooling based on commit
      messages (e.g., automatic versioning, release note generation).
         - **Reason:** Consistent formatting enables tools to reliably parse
           commit messages and perform automated actions.
  4.  **Encourage Thoughtful Commits:** Prompt developers to think about the
      purpose and impact of their changes.
         - **Reason:** A well-considered commit message often reflects a
           well-considered change.
-->
