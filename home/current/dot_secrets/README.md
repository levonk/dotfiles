# ~/.secrets Directory

## Purpose

This directory contains sensitive configuration files with credentials, API keys, and other secrets that should never be committed to version control.

## Structure

```
~/.secrets/
├── README.md           # This file
└── sourced/            # Environment files sourced by scripts
    ├── clair.env       # Clair Docker security scanner credentials
    └── .keep           # Ensures directory exists
```

## Security Guidelines

### File Permissions

- **Directory**: `700` (owner read/write/execute only)
- **Environment files**: `600` (owner read/write only)
- These permissions are enforced by chezmoi via `.chezmoiattributes`

### Best Practices

1. **Never commit actual secrets** to version control
2. **Use strong passwords** (16+ characters, mixed case, numbers, symbols)
3. **Generate passwords securely**:
   ```bash
   openssl rand -base64 32
   ```
4. **Use password managers** to store and retrieve credentials
5. **Rotate credentials regularly** in production environments
6. **Audit access** to this directory periodically

## Environment Files
- Your files should have `.env` extension

## Adding New Secret Files

1. **Create the file** in `~/.secrets/sourced/`
2. **Set permissions**: `chmod 600 ~/.secrets/sourced/your-file.env`
3. **Add EXAMPLE file to chezmoi** (if managed):
   ```bash
   chezmoi add ~/.secrets/sourced/your-file.env.example
   ```
4. **Document** the file in this README

## Backup Strategy

⚠️ **Important**: This directory contains sensitive data. When backing up:

1. **Encrypt backups** before storing
2. **Use secure storage** (encrypted drives, password managers)
3. **Never backup to cloud** without encryption
4. **Test restore procedures** regularly

## Troubleshooting

### Permission Denied Errors

If scripts can't read environment files:
```bash
chmod 700 ~/.secrets
chmod 700 ~/.secrets/sourced
chmod 600 ~/.secrets/sourced/*.env
```

### Files Not Sourced

Verify the file exists and has correct syntax:
```bash
ls -la ~/.secrets/sourced/
bash -n ~/.secrets/sourced/clair.env  # Check syntax
```

### Chezmoi Not Managing Files

Check `.chezmoiattributes` for permission rules:
```bash
grep secrets ~/.config/chezmoi/.chezmoiattributes
```

## Related Documentation

- [Clair Security Config](~/p/gh/levonk/dotfiles/docs/ssh/clair-security-config.md)
- [Chezmoi Documentation](https://www.chezmoi.io/)
- [Security Best Practices](~/p/gh/levonk/dotfiles/docs/security/)
