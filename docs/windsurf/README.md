# Modular MCP Server Configuration System

This directory contains a modular template system for managing MCP server configurations in Windsurf. The system allows you to:

1. Add/remove MCP servers in a specific order
2. Enable/disable servers conditionally
3. Maintain server configurations in separate files for better organization

## Directory Structure

```
.chezmoitemplates/dot_codeium/windsurf/
├── mcp_config.json.tmpl         # Main template (current)
├── mcp_config_blocks/           # Individual server configuration blocks
│   ├── archon.json.tmpl
│   ├── claude-code-mcp.json.tmpl
│   ├── context7.json.tmpl
│   ├── ...
│   ├── order.json.tmpl          # Server ordering and default enabled status
dot_codeium/windsurf/
├── modify_mcp_config.json.tmpl  # Template to modify existing mcp_config.json or create if it doesn't exist
dot_codeium/windsurf-next/
├── modify_mcp_config.json.tmpl  # Template to modify existing mcp_config.json or create if it doesn't exist
```

## How It Works

1. The `order.json.tmpl` file defines:
   - The order in which servers appear in the final configuration
   - Which servers are enabled by default

2. Each server has its own configuration file in the `mcp_config_blocks/` directory

3. The main template (`mcp_config_new.json.tmpl`):
   - Loads the server order and default enabled status
   - Applies any user-specific overrides
   - Assembles the final configuration in the specified order
   - Handles custom servers that don't have block files

## Customizing Server Configuration

### Adding a New Server

1. Create a new file in `mcp_config_blocks/` named `your-server-name.json.tmpl`
2. Add the server to `order.json.tmpl` in the desired position
3. Set its default enabled status in `order.json.tmpl`

### Enabling/Disabling Servers

Create a YAML file with your preferences:

```yaml
mcpServers:
  # Enable a server that's disabled by default
  claude-code-mcp: true
  
  # Disable a server that's enabled by default
  context7: false
```

### Custom Servers

If you enable a server that doesn't have a block file, the system will generate a basic configuration for it using the server name.

## How it works

1. The template checks if there is existing file content to work with
   - If the file exists, it parses the JSON content
   - If the file doesn't exist, it starts with an empty configuration
2. It loads the `order.json.tmpl` file to get the server order and default enabled status
3. It applies any user-specific overrides from the `.chezmoi.yaml` data
4. It merges the configuration using the following priority:
   - Existing server configurations are preserved
   - New servers are added based on the template blocks
   - Servers not in the template but present in the existing file are retained
5. It preserves other top-level fields like `editorconfig` if they exist

## Understanding the `modify_` Templates

### File Creation and Modification

The `modify_` prefix templates in chezmoi serve a special purpose:

1. **When a file doesn't exist:**
   - The template will be applied to create the file
   - Since there's no existing content, the template receives an empty string as input
   - The template handles this case with the check: `{{- if ne . "" -}}`

2. **When the file exists:**
   - The template receives the existing file content as input
   - It can then modify this content as needed

### How Existing Content Gets Incorporated

The flow for existing content in `~/.codeium/windsurf/mcp_config.json` works like this:

1. **When you run `chezmoi apply`:**
   - Chezmoi reads the existing file at `~/.codeium/windsurf/mcp_config.json`
   - This content is passed as the template data (`.`) to your `modify_mcp_config.json.tmpl`
   - Your template then includes the main template: `{{ includeTemplate "dot_codeium/windsurf/mcp_config.json.tmpl" . }}`

2. **In the main template (`dot_codeium/windsurf/mcp_config.json.tmpl`):**
   - It receives the existing content as `.`
   - It parses this content: `{{- $existingContent = . | fromJson -}}`
   - It extracts existing server configurations: `{{- $existingServers = $existingContent.mcpServers -}}`
   - It then merges this with the template-defined configuration

3. **The merge logic preserves:**
   - Existing server configurations when they exist
   - Other top-level fields like `editorconfig`
   - Adds new servers from the template blocks
   - Respects enabled/disabled settings

This bidirectional flow ensures that:
- User customizations in the target file are preserved
- Template-defined structure and defaults are applied
- New servers can be added to the template and will appear in the target file

The existing content never needs to be manually copied to the template - chezmoi handles passing it to the template during the apply process.

## Testing the Template

To test how the template will behave with different configurations, you can create your own test files:

1. Create a temporary YAML file (e.g., `my-test-config.yaml`) with your desired server configuration:

```yaml
# Example content for a file you would create for testing
mcpServers:
  # Enable a server that's disabled by default
  claude-code-mcp: true
  
  # Disable a server that's enabled by default
  context7: false
  
  # Add a custom server that doesn't exist in the blocks
  custom-server: true
```

2. Test the template with chezmoi execute-template:

```bash
# Create a sample input file
echo '{"mcpServers": {"existing-server": {"serverUrl": "http://example.com"}}}' > test-input.json

# Execute the template with the test input
chezmoi execute-template --data-file=my-test-config.yaml < test-input.json
```

3. Verify that the output includes:
   - The existing server configuration is preserved
   - The enabled/disabled servers are correctly configured
   - The custom server has a default configuration
