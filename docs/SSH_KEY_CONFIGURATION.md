# SSH Key Configuration Guide

This document explains how to configure SSH key naming for your dotfiles setup.

## Overview

The SSH key generation and configuration system uses a configurable git user variable to create personalized SSH key names. This allows you to customize the naming pattern while maintaining consistency across all your machines.

## SSH Key Naming Pattern

SSH keys are generated with the following naming pattern:
```
{hostname}-{git_user}-{service}-{git_user}
```

**Examples:**
- `DTOP202311-alice-github-alice`
- `laptop-bob-gitlab-bob`
- `workstation-dev-bitbucket-dev`

## Configuration Methods

### Method 1: Environment Variable (Recommended)

Set the `CHEZMOI_GIT_USER` environment variable:

**Linux/macOS/WSL:**
```bash
export CHEZMOI_GIT_USER="your-username"
```

**Windows PowerShell:**
```powershell
$env:CHEZMOI_GIT_USER = "your-username"
```

**Windows Command Prompt:**
```cmd
set CHEZMOI_GIT_USER=your-username
```

### Method 2: Persistent Environment Variable

Add to your shell profile for persistence:

**Bash (~/.bashrc or ~/.bash_profile):**
```bash
export CHEZMOI_GIT_USER="your-username"
```

**Zsh (~/.zshrc):**
```bash
export CHEZMOI_GIT_USER="your-username"
```

**PowerShell Profile:**
```powershell
$env:CHEZMOI_GIT_USER = "your-username"
```

### Method 3: Modify Chezmoi Data File

Edit `.chezmoidata.yaml` in your dotfiles repository:

```yaml
# Git/SSH Configuration
git:
  # Override the default git user
  user: "your-custom-username"
```

## Variable Resolution Priority

The system resolves the git user in the following order (highest to lowest priority):

1. **`CHEZMOI_GIT_USER`** environment variable
2. **`chezmoi.username`** (chezmoi's detected username)
3. **`USER`** environment variable (Linux/macOS)
4. **`USERNAME`** environment variable (Windows)
5. **`"user"`** (fallback default)

## Configuration Locations

### Primary Configuration File
- **File:** `.chezmoidata.yaml` (in dotfiles root)
- **Purpose:** Default configuration and documentation
- **Scope:** Global for all machines using these dotfiles

### SSH Template Files
- **File:** `home/.chezmoitemplates/modify_dot_ssh/config.tmpl`
- **Purpose:** SSH configuration template with configurable key paths
- **Variables:** Uses `$gitUser` variable for key naming

### SSH Key Generation Scripts
- **Files:** 
  - `home/.chezmoiscripts/run_once_before_generate-ssh-keys.sh.tmpl` (Bash)
  - `home/.chezmoiscripts/run_once_before_generate-ssh-keys.ps1.tmpl` (PowerShell)
- **Purpose:** Generate SSH keys with configurable naming
- **Variables:** Uses git user variable for key names and comments

### SSH Security Validation Scripts
- **Files:**
  - `home/.chezmoiscripts/run_after_validate-ssh-security.sh.tmpl` (Bash)
  - `home/.chezmoiscripts/run_after_validate-ssh-security.ps1.tmpl` (PowerShell)
- **Purpose:** Validate SSH security and detect keys with new naming pattern
- **Pattern:** Looks for `*-*-*-*` key pattern

## Usage Examples

### Example 1: Default Behavior
Without any configuration, the system uses your system username:
```bash
# If your system username is "alice"
# Generated keys: DTOP202311-alice-github-alice
```

### Example 2: Custom Git User
Set a custom git user for all SSH keys:
```bash
export CHEZMOI_GIT_USER="myhandle"
# Generated keys: DTOP202311-myhandle-github-myhandle
```

### Example 3: Different Users on Different Machines
Use different usernames on different machines by setting the environment variable locally:

**Work Machine:**
```bash
export CHEZMOI_GIT_USER="john.doe"
# Generated keys: work-laptop-john.doe-github-john.doe
```

**Personal Machine:**
```bash
export CHEZMOI_GIT_USER="johndoe"
# Generated keys: home-pc-johndoe-github-johndoe
```

## Supported VCS Providers

The system generates SSH keys for the following providers:
- **Bitbucket** (`bitbucket-l` → `bitbucket.org`)
- **Codeberg** (`codeberg-l` → `codeberg.org`)
- **Gitea Cloud** (`gitea-l` → `gitea.com`)
- **GitHub** (`github-l` → `github.com`)
- **GitLab** (`gitlab-l` → `gitlab.com`)
- **Launchpad** (`launchpad-l` → `bazaar.launchpad.net`)
- **SourceForge** (`sourceforge-l` → `git.code.sf.net`)

## Key Features

- **🔧 Configurable:** Override git user via environment variable
- **🏠 Machine-specific:** Each machine gets unique hostname in key names
- **🔑 Ed25519:** Uses quantum-resistant Ed25519 keys by default
- **📝 Descriptive comments:** SSH key comments include hostname and git user
- **🔒 Secure:** Follows security best practices for SSH configuration
- **🖥️ Cross-platform:** Works on Windows, Linux, and macOS

## Troubleshooting

### Check Current Configuration
To see what git user will be used:
```bash
chezmoi data | grep -A5 git
```

### Regenerate Keys with New Username
1. Set the new `CHEZMOI_GIT_USER` environment variable
2. Remove existing SSH keys (backup first!)
3. Run `chezmoi apply` to regenerate keys with new naming

### Verify Key Generation
Check that keys were generated with the correct naming:
```bash
ls ~/.ssh/*-*-*-* | head -5
```

## Security Notes

- SSH keys use Ed25519 algorithm for quantum resistance
- Private keys have 600 permissions, public keys have 644
- SSH configuration enforces Protocol 2 and secure cipher suites
- Host key checking is enabled to prevent MITM attacks
- Agent and X11 forwarding are disabled by default

## Migration from Old Naming

If you have existing SSH keys with the old `*-levonk-*-levonk` pattern, you can:

1. **Keep existing keys:** The system will detect and use them
2. **Migrate gradually:** Generate new keys as needed
3. **Bulk migrate:** Rename existing keys to match the new pattern

The SSH security validation scripts will detect both old and new naming patterns during the transition period.
