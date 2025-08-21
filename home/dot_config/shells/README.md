# Shell Configuration Directory

This directory contains the modular shell configuration system for the dotfiles repository, designed for high performance, maintainability, and cross-shell compatibility.

## 🏗️ **Architecture Overview**

The shell configuration system uses a **performance-optimized entrypoint** that provides:
- **Caching** for frequently sourced files
- **Lazy loading** for optional modules
- **Redundancy protection** to prevent double-loading
- **Performance timing** and bottleneck detection
- **Shell detection** and automatic configuration loading

## 📁 **Directory Structure**

```
shells/
├── shared/           # Shell-neutral configurations (bash, zsh, etc.)
│   ├── entrypointrc.sh  # 🚀 Performance-optimized entry point
│   ├── sharedrc         # Legacy shared configuration
│   ├── env/            # Environment variables and exports
│   ├── util/           # Utility functions and performance tools
│   ├── aliases/        # Command aliases and modern tool mappings
│   └── prompts/        # Shell-neutral prompt configurations
├── bash/             # Bash-specific configurations
│   ├── entrypoint.bash # Bash entry point (delegates to entrypointrc.sh)
│   ├── env/           # Bash-specific environment variables
│   ├── util/          # Bash-specific utility functions
│   ├── aliases/       # Bash-specific aliases
│   ├── completions/   # Bash completion scripts
│   └── prompts/       # Bash prompt configurations
└── zsh/              # Zsh-specific configurations
    ├── entrypoint.zsh # Zsh entry point (delegates to entrypointrc.sh)
    ├── env/          # Zsh-specific environment variables
    ├── util/         # Zsh-specific utility functions
    ├── aliases/      # Zsh-specific aliases
    ├── completions/  # Zsh completion scripts
    └── prompts/      # Zsh prompt configurations
```

## 🚀 **Entry Points**

### **Primary Entry Point: `shared/entrypointrc.sh`**
The main performance-optimized entry point that:
- Automatically detects current shell (bash/zsh)
- Loads configurations in optimal order
- Provides caching, lazy loading, and performance monitoring
- Handles both shared and shell-specific configurations

### **Shell-Specific Entry Points**
- **`bash/entrypoint.bash`**: Delegates to `entrypointrc.sh` for bash sessions
- **`zsh/entrypoint.zsh`**: Delegates to `entrypointrc.sh` for zsh sessions

## 📂 **Directory Purposes**

### **`env/` - Environment Variables**
Contains shell scripts that export environment variables and configure the shell environment.

**Common files:**
- `__xdg-env.sh` - XDG Base Directory specification compliance
- `exports.sh` - General environment exports
- `path.sh` - PATH modifications

**Tools that use this:**
- [XDG Base Directory Specification](https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html)
- [Environment Modules](http://modules.sourceforge.net/)

### **`util/` - Utility Functions**
Contains reusable shell functions and performance optimization utilities.

**Performance utilities:**
- `sourcing-registry.sh` - Prevents redundant sourcing
- `file-cache.sh` - Caches frequently sourced files
- `lazy-loader.sh` - Lazy loading for optional modules
- `performance-timing.sh` - Startup timing and bottleneck detection

**Tools that benefit:**
- [bats](https://github.com/bats-core/bats-core) - Bash testing framework
- [shellcheck](https://github.com/koalaman/shellcheck) - Shell script linting

### **`aliases/` - Command Aliases**
Contains command aliases, including modern tool replacements and shortcuts.

**Common files:**
- `modern-tools.sh` - Modern CLI tool aliases (exa→ls, bat→cat, etc.)
- `git-aliases.sh` - Git command shortcuts

**Modern tools referenced:**
- [exa](https://github.com/ogham/exa) / [eza](https://github.com/eza-community/eza) - Modern `ls` replacement
- [bat](https://github.com/sharkdp/bat) - Modern `cat` replacement with syntax highlighting
- [fd](https://github.com/sharkdp/fd) - Modern `find` replacement
- [ripgrep](https://github.com/BurntSushi/ripgrep) - Modern `grep` replacement
- [fzf](https://github.com/junegunn/fzf) - Fuzzy finder
- [delta](https://github.com/dandavison/delta) - Modern git diff viewer

### **`completions/` - Tab Completion**
Contains shell completion scripts for commands and tools.

**Shell-specific completion systems:**
- **Bash**: Uses [bash-completion](https://github.com/scop/bash-completion)
- **Zsh**: Uses built-in [zsh completion system](https://zsh.sourceforge.io/Doc/Release/Completion-System.html)

**Tools that provide completions:**
- [Git](https://git-scm.com/) - Version control
- [Docker](https://www.docker.com/) - Containerization
- [kubectl](https://kubernetes.io/docs/reference/kubectl/) - Kubernetes CLI
- [npm](https://www.npmjs.com/) / [yarn](https://yarnpkg.com/) - Node.js package managers

### **`prompts/` - Shell Prompts**
Contains shell prompt configurations and themes.

**Popular prompt tools:**
- [Starship](https://starship.rs/) - Cross-shell prompt
- [Oh My Zsh](https://ohmyz.sh/) - Zsh framework
- [Powerlevel10k](https://github.com/romkatv/powerlevel10k) - Zsh theme
- [Bash-it](https://github.com/Bash-it/bash-it) - Bash framework

## ⚡ **Performance Features**

### **Caching System**
- **Location**: `${XDG_CACHE_HOME:-$HOME/.cache}/dotfiles/`
- **TTL**: 1 hour (configurable via `DOTFILES_CACHE_TTL`)
- **Benefits**: Faster shell startup for frequently sourced files

### **Lazy Loading**
- **Triggers**: Command-based (e.g., `ls` triggers modern-tools aliases)
- **Modules**: Optional utilities and shell-specific features
- **Benefits**: Reduced startup time, load-on-demand functionality

### **Performance Monitoring**
Available aliases for performance analysis:
```bash
dotfiles-perf      # Show performance statistics
dotfiles-lazy      # Show lazy loading status
dotfiles-cache     # Show cache statistics
dotfiles-sourced   # Show sourcing registry
dotfiles-analyze   # Analyze performance bottlenecks
```

## 🔧 **Configuration**

### **Environment Variables**
```bash
# Enable performance tracking (default: 0)
export DOTFILES_PERFORMANCE_ENABLED=1

# Enable file caching (default: 1)
export DOTFILES_CACHE_ENABLED=1

# Enable debug output (default: unset)
export DEBUG_SOURCING=1

# Cache TTL in seconds (default: 3600)
export DOTFILES_CACHE_TTL=3600

# Performance warning threshold in ms (default: 100)
export DOTFILES_PERFORMANCE_THRESHOLD=100
```

## 🧪 **Testing**

The shell configuration system includes comprehensive testing:
- **BDD Tests**: `internal-docs/requirements/*.feature`
- **Shell Tests**: `internal-docs/requirements/steps/*.sh`
- **CI/CD**: `.github/workflows/test-dotfiles.yml`

**Testing tools:**
- [bats](https://github.com/bats-core/bats-core) - Bash Automated Testing System
- [shellcheck](https://github.com/koalaman/shellcheck) - Shell script static analysis

## 📚 **Usage Examples**

### **Basic Usage**
Shell entrypoints are automatically sourced by shell RC files:
```bash
# In ~/.bashrc or ~/.zshrc
source ~/.config/shells/bash/entrypoint.bash  # for bash
source ~/.config/shells/zsh/entrypoint.zsh    # for zsh
```

### **Performance Debugging**
```bash
# Enable debug mode
export DEBUG_SOURCING=1

# Start new shell and view performance report
bash  # or zsh
dotfiles-perf
```

### **Custom Module Registration**
```bash
# Register a custom module for lazy loading
register_lazy_module "my_custom_module" "/path/to/module.sh" "trigger1,trigger2"
```

## 🔗 **Related Documentation**

- [Dotfiles Migration Checklist](../../dotfiles-migration-checklist.md)
- [Admin Licenses](../../admin/licenses.md)
- [Test Requirements](../../internal-docs/requirements/)
- [Performance Specifications](../../internal-docs/specs/202508131000improvements/)

## 🤝 **Contributing**

When adding new shell configurations:
1. Place shared functionality in `shared/`
2. Place shell-specific functionality in `{bash,zsh}/`
3. Use appropriate subdirectories (`env/`, `util/`, `aliases/`, etc.)
4. Add tests in `internal-docs/requirements/`
5. Update this README if adding new directories or concepts

## 📄 **License**

See [admin/licenses.md](../../admin/licenses.md) for licensing information.
