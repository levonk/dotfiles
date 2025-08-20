# Chezmoi Pattern: Inserting or Updating Structured Files

## Objective

The goal is to properly manage structured files (like JSON, YAML, TOML) with Chezmoi in a way that:

1. Creates the path/file if it doesn't yet exist
2. Preserves existing content if it exists
3. Avoids executable permission issues
4. Handles complex templating without errors
5. Ensures proper file generation regardless of environment

## Problem Identification

You're likely doing it wrong if:

- You encounter `exec format error` when running `chezmoi apply`
- Your structured files have executable permissions (`-rwxrwxrwx`)
- Complex templates fail with errors like "index out of range" or "cannot index"
- You're using `modify_` templates with complex logic directly
- Generated files have incorrect permissions or content

## Recommended Approaches

### Approach 1: Direct File + Script Approach (Preferred)

This approach completely avoids the `modify_` template issues by using a direct file and scripts:

#### 1. Simple Direct File Template

Create a simple `dot_filename.json` template with minimal content:

```json
{
  "keyName": {}
}
```

This template:
- Is a direct file that will be placed at the target location
- Contains only the minimal structure needed
- Avoids complex templating logic entirely

#### 2. Run-Before Script to Ensure Directories

Create a `.chezmoiscripts/run_once_before_create_directories.sh.tmpl` script:

```bash
#!/bin/bash
set -euo pipefail

# Ensure directories exist
mkdir -p "{{ .chezmoi.homeDir }}/path/to/target/directory"
```

#### 3. Run-After Script for Complex Logic

Create a `.chezmoiscripts/run_after_generate_filename.sh.tmpl` script:

```bash
#!/bin/bash
set -euo pipefail

TARGET_FILE="{{ .chezmoi.homeDir }}/path/to/target/file.json"
echo "Generating structured file..."

# Read existing content if it exists
EXISTING_CONTENT="{}"
if [ -f "${TARGET_FILE}" ] && [ -s "${TARGET_FILE}" ]; then
  EXISTING_CONTENT=$(cat "${TARGET_FILE}")
fi

# Generate new content with simple logic
NEW_CONFIG="{"
NEW_CONFIG="${NEW_CONFIG}\n  \"keyName\": {\"value\": \"example\"}"
NEW_CONFIG="${NEW_CONFIG}\n}"

# Write the new content
echo -e "${NEW_CONFIG}" > "${TARGET_FILE}"

# Fix permissions
chmod -x "${TARGET_FILE}"

echo "File generated successfully"
```

#### 4. File Permissions Management

Add entries to `.chezmoiattributes` to explicitly set permissions:

```
/path/to/target/file.json -executable
```

### Approach 2: Two-Step Approach with Modify Template

#### 1. Minimal Modify Template

Create a minimal `modify_` template that only ensures the file exists with basic structure:

```go
{{- /* chezmoi:modify-template */ -}}
{{- if (stat .chezmoi.targetFile) -}}
{{- .chezmoi.stdin -}}
{{- else -}}
{
  "keyName": {}
}
{{- end -}}
```

This template:
- Uses the `chezmoi:modify-template` directive
- Preserves existing content if the file exists
- Creates a minimal structure if the file doesn't exist
- Avoids complex logic that could cause permission or execution issues

#### 2. Run-After Script for Complex Logic

Create a `.chezmoiscripts/run_after_generate_filename.sh.tmpl` script that:

1. Reads the existing file
2. Applies complex templating logic
3. Writes the result back
4. Explicitly sets correct permissions

```bash
#!/bin/bash
set -euo pipefail

TARGET_FILE="{{ .chezmoi.homeDir }}/path/to/target/file.json"
echo "Generating structured file..."

# Ensure directory exists
mkdir -p "$(dirname "${TARGET_FILE}")"

# Read existing content if it exists
EXISTING_CONTENT="{}"
if [ -f "${TARGET_FILE}" ]; then
  EXISTING_CONTENT=$(cat "${TARGET_FILE}")
fi

# Generate new content with complex logic
NEW_CONTENT=$(cat << 'EOF'
{{- /* Complex templating logic here */ -}}
{
  "key": "value"
}
EOF
)

# Write the new content
echo "${NEW_CONTENT}" > "${TARGET_FILE}"

# Fix permissions
chmod -x "${TARGET_FILE}"

echo "File generated successfully"
```

#### 3. File Permissions Management

Add entries to `.chezmoiattributes` to explicitly set permissions:

```
/path/to/target/file.json -executable
```

## Wrong Approaches and Why They Fail

### Anti-Pattern 1: Complex Modify Templates

```go
{{- /* chezmoi:modify-template */ -}}
{{- /* Complex logic with multiple includes and nested JSON parsing */ -}}
```

**Why it fails:**
- Temporary files created during `modify_` operations inherit source file permissions
- Complex templates are harder to debug when they fail
- Execution errors occur when JSON files have executable permissions

### Anti-Pattern 2: Direct Templates with Executable Bit

```go
{{- /* Direct template with complex logic */ -}}
```

**Why it fails:**
- Templates in source control often have executable permissions
- Chezmoi preserves these permissions in the target files
- JSON/YAML/TOML files should never be executable

### Anti-Pattern 3: Relying on includeTemplate for Structured Files

```go
{{ includeTemplate "path/to/complex/template.tmpl" . }}
```

**Why it fails:**
- Included templates may have different permissions
- Path resolution can be inconsistent across environments
- Error handling is limited

## Real-World Example: MCP Config JSON

### Problem:
- MCP config JSON files were being generated with executable permissions
- This caused `exec format error` when Chezmoi tried to apply them
- Complex nested JSON structure made templating error-prone

### Solution (Direct File + Script Approach):

1. **Simple direct file template:**
```json
{
  "mcpServers": {}
}
```

2. **Run-once-before script to ensure directories exist:**
```bash
#!/bin/bash
set -euo pipefail

# Create directories for MCP configs
mkdir -p "{{ .chezmoi.homeDir }}/.codeium/windsurf"
mkdir -p "{{ .chezmoi.homeDir }}/.codeium/windsurf-next"
```

3. **Run-after script for complex logic:**
```bash
#!/bin/bash
set -euo pipefail

MCP_CONFIG_FILE="{{ .chezmoi.homeDir }}/.codeium/windsurf-next/mcp_config.json"

# Read existing content if it exists
EXISTING_CONTENT="{}"
if [ -f "${MCP_CONFIG_FILE}" ] && [ -s "${MCP_CONFIG_FILE}" ]; then
  EXISTING_CONTENT=$(cat "${MCP_CONFIG_FILE}")
fi

# Generate new config with simple logic
NEW_CONFIG="{"
NEW_CONFIG="${NEW_CONFIG}\n  \"mcpServers\": {"
NEW_CONFIG="${NEW_CONFIG}\n    \"archon\": {"
NEW_CONFIG="${NEW_CONFIG}\n      \"command\": \"npx\","
NEW_CONFIG="${NEW_CONFIG}\n      \"args\": ["
NEW_CONFIG="${NEW_CONFIG}\n        \"-y\","
NEW_CONFIG="${NEW_CONFIG}\n        \"@modelcontextprotocol/server-archon\""
NEW_CONFIG="${NEW_CONFIG}\n      ],"
NEW_CONFIG="${NEW_CONFIG}\n      \"env\": {}"
NEW_CONFIG="${NEW_CONFIG}\n    }"
NEW_CONFIG="${NEW_CONFIG}\n  }"
NEW_CONFIG="${NEW_CONFIG}\n}"

# Write the new content
echo -e "${NEW_CONFIG}" > "${MCP_CONFIG_FILE}"

# Fix permissions
chmod -x "${MCP_CONFIG_FILE}"
```

4. **Explicit permission management:**
```
/.codeium/windsurf/mcp_config.json -executable
/.codeium/windsurf-next/mcp_config.json -executable
```

## Best Practices

1. **Prefer direct file + script approach** - Completely avoids modify template issues
2. **Keep templates minimal** - They should only ensure the file exists with basic structure
3. **Use run_after scripts for complex logic** - This separates templating from file management
4. **Explicitly manage permissions** - Always set `-executable` for structured data files
5. **Test in different environments** - Ensure your approach works across Linux, macOS, and Windows
6. **Handle errors gracefully** - Include proper error checking in scripts
7. **Document your approach** - Make it clear how the files are being managed

## Debugging Tips

If you encounter issues:

1. Check file permissions with `ls -la`
2. Use `chezmoi apply --verbose` to see detailed operations
3. Inspect temporary files created during apply
4. Check if Git is preserving file modes with `git config core.filemode`
5. Verify `.chezmoiattributes` is being applied correctly
