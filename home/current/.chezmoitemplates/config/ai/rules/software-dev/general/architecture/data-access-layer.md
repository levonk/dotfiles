### Data Access Layer (DAL)

A Data Access Layer (DAL) is a dedicated, centralized part of your application responsible for all data-related operations. It abstracts the underlying data source (e.g., database, API) from your business logic.

- **Centralize Logic**: Consolidate all data fetching, caching, and mutation logic into a single location (e.g., a `src/data/` or `src/lib/data` directory).
- **Single Source of Truth**: By centralizing data access, you create a single source of truth for how data is retrieved and modified. This simplifies debugging and maintenance.
- **Security Checkpoint**: The DAL provides a natural and effective checkpoint to enforce authorization and validate user permissions before any data is accessed or returned.
