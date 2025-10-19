# Clair Docker Security Scanner Configuration

## Overview

The `docker-security-check` script now sources configuration from `~/.secrets/sourced/clair.env` to externalize sensitive credentials and configuration.

## Setup Instructions

1. **Create the secrets directory** (if it doesn't exist):
   ```bash
   mkdir -p ~/.secrets/sourced
   chmod 700 ~/.secrets
   chmod 700 ~/.secrets/sourced
   ```

2. **Copy the example configuration**:
   ```bash
   cp ~/p/gh/levonk/dotfiles/docs/examples/clair.env.example ~/.secrets/sourced/clair.env
   ```

3. **Edit the configuration file**:
   ```bash
   $EDITOR ~/.secrets/sourced/clair.env
   ```

4. **Set secure permissions**:
   ```bash
   chmod 600 ~/.secrets/sourced/clair.env
   ```

## Configuration Variables

The following variables can be set in `~/.secrets/sourced/clair.env`:

- **`CLAIR_DB_USER`**: PostgreSQL database username (default: `clairuser`)
- **`CLAIR_DB_PASSWORD`**: PostgreSQL database password (default: `MySecretClairPass123!`)
- **`CLAIR_DB_NAME`**: PostgreSQL database name (default: `clair`)
- **`CLAIR_API_PORT`**: Port for Clair API service (default: `6060`)

## Security Best Practices

1. **Always change the default password** in production environments
2. **Never commit** `~/.secrets/` directory to version control
3. **Use strong passwords** (minimum 16 characters, mixed case, numbers, symbols)
4. **Restrict file permissions** to owner-only (600)
5. **Consider using a password manager** to generate and store credentials

## Fallback Behavior

If `~/.secrets/sourced/clair.env` is not found, the script will:
- Use default values (with a warning in commented echo statements)
- Continue execution with insecure defaults
- Display a warning message about creating the configuration file

## Related Files

- Script: `~/.local/bin/service/docker-security-check`
- Example: `~/p/gh/levonk/dotfiles/docs/examples/clair.env.example`
- Source: `~/p/gh/levonk/dotfiles/home/current/dot_local/bin/service/executable_docker-secuirty-check.bash.tmpl`
