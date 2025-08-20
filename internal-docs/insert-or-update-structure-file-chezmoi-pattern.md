# Chezmoi Pattern: Inserting or Updating Structured Files

## Objective

The goal is to properly manage structured files (like JSON, YAML, TOML) with Chezmoi in a way that:

1. Preserves existing content when appropriate
2. Avoids executable permission issues
3. Handles complex templating without errors
4. Ensures proper file generation regardless of environment

## Problem Identification

You're likely doing it wrong if:

- You encounter `exec format error` when running `chezmoi apply`
- Your structured files have executable permissions (`-rwxrwxrwx`)
- Complex templates fail with errors like "index out of range" or "cannot index"
- You're using `modify_` templates with complex logic directly
- Generated files have incorrect permissions or content

## The Right Way: Two-Step Approach

### 1. Minimal Modify Template

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

### 2. Run-After Script for Complex Logic

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

### 3. File Permissions Management

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

### Solution:

1. **Minimal modify template:**
```go
{{- /* chezmoi:modify-template */ -}}
{{- if (stat .chezmoi.targetFile) -}}
{{- .chezmoi.stdin -}}
{{- else -}}
{
  "mcpServers": {}
}
{{- end -}}
```

2. **Run-after script for complex logic:**
```bash
#!/bin/bash
set -euo pipefail

MCP_CONFIG_FILE="{{ .chezmoi.homeDir }}/.codeium/windsurf-next/mcp_config.json"

# Complex templating logic to generate the file
# ...

# Fix permissions
chmod -x "${MCP_CONFIG_FILE}"
```

3. **Explicit permission management:**
```
/.codeium/windsurf/mcp_config.json -executable
/.codeium/windsurf-next/mcp_config.json -executable
```

## Best Practices

1. **Keep modify templates minimal** - They should only ensure the file exists with basic structure
2. **Use run_after scripts for complex logic** - This separates templating from file management
3. **Explicitly manage permissions** - Always set `-executable` for structured data files
4. **Test in different environments** - Ensure your approach works across Linux, macOS, and Windows
5. **Handle errors gracefully** - Include proper error checking in scripts
6. **Document your approach** - Make it clear how the files are being managed

## Debugging Tips

If you encounter issues:

1. Check file permissions with `ls -la`
2. Use `chezmoi apply --verbose` to see detailed operations
3. Inspect temporary files created during apply
4. Check if Git is preserving file modes with `git config core.filemode`
5. Verify `.chezmoiattributes` is being applied correctly
