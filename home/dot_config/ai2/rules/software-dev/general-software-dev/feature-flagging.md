# When adding or removing feature flags from the code base.

 Essential patterns for working with feature flags follow these

 **use when:** adding or removing feature flags for development.

## Critical commands

## Adding feature flags

### when asked to create a feature flag
- check to see if you have access to the MCP tool
- If not, let the user know you don't have access to the MCP tool.
- If you do have access, use that tool to create a flag.
- Flag should be of type boolean unless otherwise specified.
-  If the flag is going to be used in front end code set the client side availability,
- Always provide a direct link to the created flag immediately after successful flag creation.
- format: Flag name
-  Replace PROJECT KEY with the actual project key used
-   Replace FLAG KEY with the actual flag key created
-   

- Use consistent naming conventions:
  - kebab-case for flag keys
  - PascalCase for backend methods
  - CamelCase for frontent functions