# Licenses and Legal Information

This document tracks licensing information for the dotfiles repository and its dependencies.

## Repository License

This dotfiles repository is provided under the MIT License (see LICENSE file in root directory).

## Third-Party Dependencies and Tools

### Shell Tools and Utilities
- **bats**: MIT License - Bash Automated Testing System
- **shellcheck**: GPL v3 - Shell script static analysis tool
- **chezmoi**: MIT License - Dotfiles management tool

### Git Tools
- **git**: GPL v2 - Version control system
- **diff-so-fancy**: MIT License - Git diff enhancement (if used)
- **delta**: MIT License - Git diff viewer (if used)

### Modern CLI Tools (Optional Dependencies)
- **exa/eza**: MIT License - Modern `ls` replacement
- **bat**: MIT License - Modern `cat` replacement
- **fd**: MIT License - Modern `find` replacement
- **ripgrep**: MIT License - Modern `grep` replacement
- **fzf**: MIT License - Fuzzy finder

### Development Tools
- **ctags**: GPL v2 - Source code indexing
- **vim/neovim**: Vim License/Apache 2.0 - Text editors

## Compliance Notes

1. **GPL Dependencies**: Some tools (git, shellcheck, ctags) are GPL-licensed. This repository only configures these tools and does not redistribute them.

2. **MIT Dependencies**: Most modern CLI tools use MIT license, which is compatible with this repository's MIT license.

3. **Configuration Only**: This repository contains only configuration files, not the actual tools themselves. Users must install tools separately according to their respective licenses.

## License Compatibility

All configuration files in this repository are original work or adaptations that maintain compatibility with the MIT License. No GPL code is included in the configuration files themselves.

## Attribution

When configuration snippets are adapted from other sources, attribution is provided in comments within the relevant configuration files.

## Updates

This license information should be reviewed and updated when:
- New tools are added to the configuration
- Existing tool dependencies change their licensing
- New third-party configuration snippets are incorporated

Last updated: 2025-08-13
