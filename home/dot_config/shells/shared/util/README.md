# Shared Utility Functions

This directory contains **shell-neutral** utility functions and performance optimization tools that work across all POSIX-compatible shells.

## 🚀 **Performance Utilities**

### **`sourcing-registry.sh`** - Redundancy Protection
Prevents files from being sourced multiple times and tracks loaded modules.

**Key Functions:**
- `is_already_sourced()` - Check if file was already sourced
- `mark_as_sourced()` - Mark file as sourced in registry
- `safe_source()` - Source with redundancy protection
- `get_sourcing_stats()` - Show sourcing statistics

### **`file-cache.sh`** - File Caching System
Caches frequently sourced files to improve shell startup performance.

**Key Functions:**
- `cached_source()` - Source with caching
- `is_cache_valid()` - Check cache validity (TTL + modification time)
- `clean_cache()` - Remove old cache files
- `get_cache_stats()` - Show cache statistics

**Cache Location:** `${XDG_CACHE_HOME:-$HOME/.cache}/dotfiles/`

### **`lazy-loader.sh`** - Lazy Loading Framework
Load optional modules only when needed to improve startup performance.

**Key Functions:**
- `register_lazy_module()` - Register module for lazy loading
- `load_lazy_module()` - Load module on-demand
- `preload_essential_modules()` - Load critical modules immediately
- `get_lazy_stats()` - Show lazy loading statistics

### **`performance-timing.sh`** - Performance Monitoring
Measure and track shell startup and sourcing performance.

**Key Functions:**
- `start_timing()` / `end_timing()` - Time code sections
- `time_command()` - Time command execution
- `get_performance_stats()` - Show performance data
- `analyze_performance_bottlenecks()` - Identify slow operations

## 🔧 **General Utilities**

This directory can also contain:
- **Helper functions** for common shell operations
- **Cross-shell compatibility** functions
- **Text processing** utilities
- **File manipulation** helpers

## 📊 **Performance Monitoring**

Use these aliases to monitor performance:
```bash
dotfiles-perf      # Show performance statistics
dotfiles-lazy      # Show lazy loading status
dotfiles-cache     # Show cache statistics  
dotfiles-sourced   # Show sourcing registry
dotfiles-analyze   # Analyze performance bottlenecks
```

## 🔗 **Related Tools**

**Performance Analysis:**
- [hyperfine](https://github.com/sharkdp/hyperfine) - Command-line benchmarking
- [time](https://www.gnu.org/software/time/) - Time command execution
- [strace](https://strace.io/) - System call tracing

**Shell Development:**
- [shellcheck](https://github.com/koalaman/shellcheck) - Shell script linting
- [shfmt](https://github.com/mvdan/sh) - Shell script formatting
- [bats](https://github.com/bats-core/bats-core) - Bash testing framework

## ⚙️ **Configuration**

Control performance features:
```bash
# Enable performance tracking
export DOTFILES_PERFORMANCE_ENABLED=1

# Enable file caching
export DOTFILES_CACHE_ENABLED=1

# Cache TTL in seconds (default: 3600)
export DOTFILES_CACHE_TTL=3600

# Performance warning threshold in ms (default: 100)
export DOTFILES_PERFORMANCE_THRESHOLD=100
```

## 📝 **Adding New Utilities**

1. Create `.sh` files with descriptive names
2. Use POSIX-compatible syntax for maximum compatibility
3. Include comprehensive error handling
4. Add function documentation and examples
5. Export functions for interactive use:
   ```bash
   if [ -n "${FOO:-}" ]; then
       export -f my_foo_function
   fi
   ```

## 🧪 **Testing**

Utility functions should be tested with:
- Multiple shells (bash, zsh, dash)
- Various operating systems
- Different edge cases and error conditions
- Performance benchmarks
