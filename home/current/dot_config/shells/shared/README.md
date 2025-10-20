# Shared Shell Configurations

This directory contains **shell-neutral** configurations that work across all POSIX-compatible shells (bash, zsh, dash, etc.).

## 🚀 **Entry Points**

### **`entrypointrc.sh`** - Performance-Optimized Entry Point
The main entry point that provides:
- **Caching** for frequently sourced files
- **Lazy loading** for optional modules  
- **Redundancy protection** to prevent double-loading
- **Performance timing** and bottleneck detection
- **Automatic shell detection** and configuration loading
- **Symbolic Link Support** for modular configurations

**Usage:**
```bash
source ~/.config/shells/shared/entrypointrc.sh
```

### **`sharedrc`** - Legacy Shared Configuration
Traditional shared configuration file for backward compatibility.

## 📁 **Subdirectories**

### **`env/`** - Environment Variables
Shell-neutral environment variable exports and XDG compliance.

### **`util/`** - Utility Functions
Reusable shell functions and performance optimization utilities.

### **`aliases/`** - Command Aliases
Shell-neutral aliases and modern tool replacements.

### **`prompts/`** - Prompt Configurations
Shell-neutral prompt configurations and themes.

## ⚡ **Performance Features**

The `entrypointrc.sh` provides these performance monitoring aliases:
```bash
dotfiles-perf      # Show performance statistics
dotfiles-lazy      # Show lazy loading status  
dotfiles-cache     # Show cache statistics
dotfiles-sourced   # Show sourcing registry
dotfiles-analyze   # Analyze performance bottlenecks
```

## 🔧 **Configuration**

Enable performance features:
```bash
export DOTFILES_PERFORMANCE_ENABLED=1  # Enable timing
export DOTFILES_CACHE_ENABLED=1        # Enable caching
export DEBUG_SOURCING=1                # Enable debug output
```

## 📚 **Related**

- [Bash-specific configurations](../bash/)
- [Zsh-specific configurations](../zsh/)
- [Shell directory overview](../README.md)
