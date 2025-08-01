# Security-Sensitive File Patterns

This file defines patterns for security-sensitive files that should never be committed to version control or included in packages.

## Purpose

Security file patterns help prevent accidental exposure of sensitive information by excluding:
1. **Credentials and secrets** (API keys, passwords, tokens)
2. **Encryption keys** (private keys, certificates)
3. **Environment files** with sensitive configuration
4. **Access control files** (htaccess, auth configs)
5. **Backup files** containing sensitive data

## Usage

These patterns are included in:
- `.gitignore` (Version Control)
- `.npmignore` (Packaging)
- `.codeiumignore` (AI Assistant)
- `.cursorignore` (AI Assistant)

## Common Patterns

```gitignore
# Credentials and secrets
.env
.env.*
!.env.example
*.pem
*.key
*.p12
*.pfx
*.crt
*.cer
*.p7b
*.p7c
*.p7s
*.p8
*.pkcs12
*.pkcs8
*.asc
*.gpg
*.pgp
*.kdbx
*.keychain

# Environment files
*.env.local
*.env.*.local
.env.development.local
.env.test.local
.env.production.local

# Access control
.htpasswd
.htaccess
access.txt

# Sensitive configs
*config*.json
*secret*.json
*credential*.json

# Backup files containing sensitive data
*.bak
*.backup
*.old
*.swp
*~
```

## Related Documentation

- [Ignore Files Overview](../docs/meta/ignorefiles/README.md)
- [Security Ignore Patterns](../docs/meta/ignorefiles/security-ignore-files.md)

# ============================================================================
# **DO NOT EDIT DIRECTLY** - This file is autogenerated by generate-ignores.js
# ============================================================================
#
# This file combines patterns from:
# - @file:.config/filelists/security.ignorefile.md (Security patterns - Markdown)
# - @file:.config/filelists/security.ignorefile (Security patterns - non-Markdown)
#
# Last generated: {{GENERATED_TIMESTAMP}}
#
# To modify these patterns, edit the appropriate source files above and regenerate.
