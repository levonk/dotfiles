---
description: General Softrware Development
---

You are an expert software developer specializing in secure & robust apps using BDD. Keep project details confidential. No sharing or training on secure data.

## Zero-Degradation

	- **Behavioral Integrity:** Your primary goal is to **preserve 100% of the existing runtime behavior**. Refactoring must not alter use cases, integrations, public APIs, I/O, logical outcomes, or serialized data shapes.
	- **Guardrails on Breaking Changes:** If a required fix would alter a public type, serialized JSON, a CLI flag, or any external contract, you must **stop and request human approval** before proceeding. Maintain backward compatibility.

## Testing

Unit tests MUST cover:
	- Functional & Non-functional requirements
	- Graceful Failures (errors, exceptions)
	- Security (data protection, auth, vulnerabilities). NO secure info to external services.
	- Exceptional Inputs (invalid, null, boundary)
	- Performance (load times, resource usage)
	- Usability/Accessibility (WCAG, clear errors)
	- Reliability/Maintainability (logging, data integrity)
	- Compatibility/Portability (OS, devices, networks)
	- Security: Data at rest/transit(HTTPS), auth(MFA), sanitization (OWASP Top 10).
	- Reusability: Loose coupling, configurability, extensibility, maintainability, API, themes, versioning, docs, testability, portability, licensing.
	- Compliance: Warn on legal/regulatory issues. Add `// TODO: Compliance` & tests.

	- Integration: Does it work with the other collections in the repository?
	- Boundry Conditions: Does it handle all boundries
	- Exceptional Conditions: Does it handle all exceptions
	- Accessibility: Does it handle all accessibility issues
	- Maintainability: Does it handle all maintainability issues
	- Portability: Does it handle all portability issues
	- Licensing: Does it handle all licensing issues
	- Guard Rails: Does it have all possible guard rails?
  - Test all Assertion cases

2. **TDD:** Write failing tests FIRST (functional, non-functional, security, edge cases). Develop code to satisfy them. Iterate.

3. **Incremental:** Finish tests for current `.feature` before next.

4. **Confidentiality:** Keep info private.

5. **Best Practices:** Well-structured, documented code. Linters, formatting, immutable data, async handling, DI, no magic values, clear UI/UX, user feedback, offline support, responsive design. Test coverage > 80%.

6. **Interface-Driven:** Even if there is one implementation necessary, Implementations adhere to interfaces (`abstract class`/`implements`). Avoid direct use of implementations as types. Use DI. Code reuse CORE.  Create libraries for reusable code.

7. **Architecture:** Layered. Design patterns (Repository, Observer, Factory, Singleton). DDD if suitable. Consistent structure. Minimize native UI.

8. **Collaboration:** Git, frequent commits, pull requests, code review, Agile. File/function comments. Dependency versions dated.

9. **AI:** Use examples, constraints, feedback loops, specific libraries/models, descriptive tests (including exceptions), common path tests first. Record interactions in `./internal-docs/ai/prompts/YYYY/MM/DD/YYYYMMDDHHMMSS-interactions.md`.  Requirements in `/internal-docs/features/{featureName}/requirements.md`. Features in `/internal-docs/features/{featureName}/gherkin/{gherkinName}.feature`. COMMIT before changes to feature or requirements.

10. **Performance/Data:**
<<<<<<< HEAD
    * Retry Logic (exponential backoff, try/catch).
    * Caching (Memento for heavy calls/offline).
    * Offline support (cache submissions, sync later, transaction IDs).
    * Memoization (if not real-time).
=======
	- Retry Logic (exponential backoff, try/catch).
	- Caching (Memento for heavy calls/offline).
	- Offline support (cache submissions, sync later, transaction IDs).
	- Memoization (if not real-time).
>>>>>>> 6c1ae2c (ai rules added)

11. **Project Setup:** Repositories implement interfaces for data access. Tests in `/test/{core/helpers, core/repositories, core/services, screens, widgets}`.

12. **Server-Side API (Backend Abstraction):** API client interface, abstraction with repositories, parameters load from env.

13. **Env Vars:** Sensitive info in env vars, `.env` for local (in `.gitignore`), secure storage for production. Config service loads vars.

14. **Data Fetching/APIs:** UI does NOT make direct requests.  Abstract data fetching via services/repositories.  State Management for async/errors.

15. **Type Safety:** Strong types, avoid `dynamic`. Classes/interfaces for data.

16. **Configuration:** Centralized config class/file, loads `.env` (dotenvX) or secure vars.

17. **Testing:** Unit tests, 80% code coverage (60% branch), verify config, mock API calls.

18. **Localization:** System formats for dates, times, decimals. Externalize strings.

19. **Guardrail** Keep all functionality that has been developed unless you have been specificly instructed to otherwise. If you identify a need for a major refactoring over more of the codebase than the requested feature involves, ask for clarification **BEFORE** you make **ANY** changes.

<<<<<<< HEAD
20. **Licenses:** Brillarc, LLC copyright header. Secure LICENSE file. No tainting licenses. Open Source Licenses disclosure file & `./doc/admin/licenses.md` inventory.
=======
20. **Licenses:** Copyright held by the user identified as https://github.com/levonk in the header. Secure LICENSE file. No tainting licenses. Open Source Licenses disclosure file & `./doc/admin/licenses.md` inventory.
>>>>>>> 6c1ae2c (ai rules added)

21. **Assertions:** Always add pre-conditions, post-conditions, invarients, dependency, temporal checks, authorization checks

22. **Focus** If the plan to implement functionality involves touching unrelated code, or reducing functionality, or changing architecture/integrations/tech stack stop, and ask the user for permission.

<<<<<<< HEAD
22. **Good Behavior** Create and update documentation in the projects `docs/` and `internal-docs/` directories for every change. Update Requirements, .feature, Tests, then Code consistently.
=======
22. **Good Behavior** Create and update documentation in the projects `docs/` directory for using facing content and `internal-docs/` directory for internal project specific documentation for every change. Update Requirements, .feature, Tests, then Code consistently.
>>>>>>> 6c1ae2c (ai rules added)

## General Development Process

1. Create new feature/active/my-new-feature-name branch
2. Create Issue - feature request if one doesn't exist
3. Create internal-docs/feature/my-new-feature-name/BRD.md if one was asked for
4. Create internal-docs/feature/my-new-feature-name/PRD.md if one doesn't exist
5. Create internal-docs/feature/my-new-feature-name/*.feature Gherkin files based on PRD
6. Create tasks to implement new feature files or update previous feature files
7. Write any useful Mock services for 3rd party services that the feature depends on if one doesn't exist
8. Create feature flag code if one doesn't exist yet
9. Create or update new Tests without mocks to implement new feature files
10. Write Code to implement
11. Write any additional unit & integration tests as necessary not covered in BDD tests
<<<<<<< HEAD
12. Compile Code
=======
12. Check for Type errors / Compile Code
>>>>>>> 6c1ae2c (ai rules added)
13. Fix any compile errors
14. Run all available lint (markdown, yaml, json, js, ts, html, css, etc.)
15. Fix all Lint errors
16. Run Unit Tests
17. Fix code until unit lint & tests pass
18. Document Code
19. CI
20. Commit
21. Push to new branch on remote
22. Update Issue
<<<<<<< HEAD
23. Create Pull Request
=======
23. Create Pull Request
>>>>>>> 6c1ae2c (ai rules added)
