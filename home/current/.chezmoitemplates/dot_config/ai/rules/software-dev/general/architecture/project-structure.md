---
description: Architecture — Project Structure
---

# Project Structure

**Date**: 2025-09-26

**Status**: Accepted

## Context

The monorepo's `packages/` directory has been growing with a flat structure, where packages are grouped loosely by a high-level concept (e.g., `ai`, `auth`). As the number of packages increases, this structure is becoming difficult to navigate and scale. We anticipate needing to support multiple language-specific implementations (e.g., TypeScript, Python, Swift) for the same features in the future.

We need a more organized, scalable, and intuitive structure for our packages.

## Decision

We will adopt a domain-first, hierarchical package structure within the `packages/` directory. The structure is defined as follows:

```sh
{repo-root}/
└── internal-docs/ # e.g., cli, web, api, android, ios, mac, win, linux, posix
 └── adr
 └── features
  └── todo
   └── {feature-name}
  └── {YYYY}
   └── {feature-name}
└── apps/
 └── {business}/
  └── {app-name}/ # e.g., todo-app
   └── internal-docs/ # e.g., cli, web, api, android, ios, mac, win, linux, posix
    └── adr
    └── features
     └── todo
      └── {feature-name}
     └── {YYYY}
      └── {feature-name}
   └── {app-category}/ # e.g., homepage, tools, dashboard
    └── {interface}/ # e.g., cli, web, api, android, ios, mac, win, linux, posix
     └── {platform-language}/ # e.g., typescript, python, ios-swift
      └── src/ # the source code
      └── .devcontainer/ # the source code
└── packages/
 └── {features,services,core,ui}/
  └── {category}/ # e.g., commerce, core, ui
   └── {domain}/ # e.g., subscriptions, payments
    └── {package-name}/ # e.g., subscriptions-stripe, payments-stripe
     └── {platform-language}/ # e.g., typescript, python, swift, Kotlin
     └── typescript/
      └── packages.json

### Guiding Principle: Vertical Slicing (Feature-First)

A core principle of this architecture is to organize code by **feature (vertical slicing)** rather than by **layer (horizontal slicing)**.

This means that all the code related to a single feature—including its UI, business logic, data access, and service integrations—should be co-located within that feature's domain directory (e.g., `packages/features/commerce/`).

We explicitly avoid organizing the codebase into top-level layer directories like `packages/data/` or `packages/ui/` that serve multiple features, as this would scatter the code for a single feature across many different parts of the repository. This makes features harder to understand, maintain, and assign ownership.

### Directory Levels Explained

1. **`{category}`**: The highest level of organization. This groups packages by their broad functional purpose. Initial categories include:
    *   `features`: Core business logic and product features that represent a user-facing capability (e.g., `auth`, `commerce`, `documents`).
    *   `services`: Clients or adapters for specific, low-level external services. These do not contain business logic (e.g., `ai`, `blob-storage`).
    *   `core`: Foundational, shared utilities that are product-agnostic (e.g., `logging`, `utils`).
    *   `ui`: Shared UI components, hooks, and design system elements.

2.  **`{domain}`**: A specific business domain or technical capability. For example, under the `features` category, we might have `commerce` or `search`. Under `services`, we might have `ai` or `blob`.

3.  **`{platform-language}`**: Specifies the target platform and language for the implementation (e.g., `web-typescript`, `api-python`, `ios-swift`). For shared, language-agnostic code (like type definitions), a `shared/` directory can be used.

4.  **`{package-name}`**: The final, specific name of the package (e.g., `payments-stripe`, `subscriptions-manager`).

### Example

```sh
packages/
└── features/
    └── commerce/
        ├── payments/
        │   ├── shared/
        │   │   └── payments-types/
        │   │       └── package.json
        │   └── web-typescript/
        │       └── payments-stripe/
        │           └── package.json
        └── subscriptions/
            └── web-typescript/
                └── subscriptions-manager/
                    └── package.json
```

## Consequences

* **Pros**:
  * **Improved Discoverability**: Developers can easily find code related to a specific feature or integration.
  * **High Cohesion**: All code for a single feature domain is co-located, making it easier to reason about and maintain.
  * **Scalability**: The structure can easily accommodate new features, platforms, and languages without becoming disorganized.
  * **Clear Ownership**: It's easier to assign ownership of specific domains to teams or individuals.
* **Cons**:
  * **Increased Path Depth**: File paths will be longer, which is a minor inconvenience.
  * **Refactoring Effort**: Existing packages must be moved, and build/configuration files (`BUILD.bazel`, `tsconfig.base.json`, etc.) must be updated to reflect the new paths. This is a one-time cost.

* interface: `cli/`, `cli_logic/`, `auth/`, `config/`, `services/`, `tools/`, `theme/`, `api/`.
* Each interface exposes a clear entry module and re-exports via a local index.
* Keep modules ~1–25 files where practical; prefer composition over deep inheritance.
* Keep files ~150–200 LOC where practical; prefer composition over deep inheritance.
* Keep functions ~1–50 LOC where practical; prefer composition over deep inheritance.
- Enforce module boundaries; import only through domain public API.

See also: `dot_config/ai/rules/software-dev/general/architecture/philosophy.md`.
