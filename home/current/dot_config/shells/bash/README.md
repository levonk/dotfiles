# Bash-Specific Configurations

This directory contains configurations specific to the **Bash shell** that complement the shared shell configurations.

## 🚀 **Entry Point**

### **`entrypoint.bash`** - Bash Entry Point
The main entry point for Bash sessions that delegates to the optimized `entrypointrc.sh`:

```bash
# In ~/.bashrc
source ~/.config/shells/bash/entrypoint.bash
```

This entry point automatically:
- Detects Bash environment
- Loads Bash-specific configurations with performance optimizations
- Provides caching, lazy loading, and timing for Bash configs

## 📁 **Subdirectories**

### **`env/`** - Bash Environment Variables
Bash-specific environment variables and exports:
- Bash history settings (`HISTSIZE`, `HISTCONTROL`)
- Bash-specific tool configurations
- Shell options and behavior settings

### **`util/`** - Bash Utility Functions
Bash-specific utility functions that leverage Bash features:
- Advanced array manipulation
- Bash associative arrays
- Process substitution utilities
- Bash-specific string operations

### **`aliases/`** - Bash-Specific Aliases
Aliases that use Bash-specific features or syntax:
- Bash history manipulation
- Bash-specific shortcuts
- Aliases that leverage Bash arrays or functions

### **`completions/`** - Bash Tab Completion
Bash completion scripts using the [bash-completion](https://github.com/scop/bash-completion) framework:
- Custom command completions
- Tool-specific completion scripts
- Programmable completion functions

### **`prompts/`** - Bash Prompt Configurations
Bash-specific prompt configurations:
- PS1/PS2 prompt customizations
- Bash prompt themes
- Git integration for prompts

## 🔧 **Bash-Specific Features**

### **History Configuration**
```bash
# Common Bash history settings
export HISTSIZE=10000
export HISTFILESIZE=20000
export HISTCONTROL=ignoredups:erasedups
shopt -s histappend
```

### **Shell Options**
```bash
# Useful Bash shell options
shopt -s autocd        # cd by typing directory name
shopt -s cdspell       # correct minor spelling errors in cd
shopt -s checkwinsize  # update LINES and COLUMNS after each command
shopt -s globstar      # enable ** for recursive globbing
```

### **Programmable Completion**
```bash
# Enable bash completion
if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
fi
```

## 🔗 **Bash-Specific Tools**

**Completion Systems:**
- [bash-completion](https://github.com/scop/bash-completion) - Programmable completion framework
- [bash-it](https://github.com/Bash-it/bash-it) - Bash framework with themes and plugins

**Prompt Tools:**
- [Starship](https://starship.rs/) - Cross-shell prompt (works with Bash)
- [Powerline](https://github.com/powerline/powerline) - Statusline plugin
- [Liquid Prompt](https://github.com/nojhan/liquidprompt) - Adaptive prompt

**Development Tools:**
- [bashdb](http://bashdb.sourceforge.net/) - Bash debugger
- [shellcheck](https://github.com/koalaman/shellcheck) - Shell script linting
- [bats](https://github.com/bats-core/bats-core) - Bash testing framework

## ⚡ **Performance Features**

Bash-specific configurations benefit from:
- **Caching** for frequently sourced completion scripts
- **Lazy loading** for optional Bash modules
- **Performance timing** for Bash-specific startup operations
- **Redundancy protection** to prevent double-loading

## 📦 **Installation Requirements**

**Bash Version:**
- Minimum: Bash 4.0+ (for associative arrays and other modern features)
- Recommended: Bash 5.0+ (latest features and performance improvements)

**Check Bash version:**
```bash
bash --version
echo $BASH_VERSION
```

## 📝 **Adding Bash-Specific Configurations**

1. **Environment variables**: Add to `env/` directory
2. **Functions**: Add to `util/` directory (use Bash-specific features freely)
3. **Aliases**: Add to `aliases/` directory (can use Bash syntax)
4. **Completions**: Add to `completions/` directory (use bash-completion format)
5. **Prompts**: Add to `prompts/` directory (use PS1/PS2 variables)

### **Example Bash Function**
```bash
# In util/array-helpers.sh
# Bash-specific function using associative arrays
declare_associative_array() {
    local array_name="$1"
    shift
    declare -gA "$array_name"
    
    while [[ $# -gt 1 ]]; do
        local key="$1"
        local value="$2"
        declare -gA "${array_name}[$key]=$value"
        shift 2
    done
}
```

## 🔄 **Compatibility**

While this directory contains Bash-specific configurations:
- Shared configurations are still loaded from `../shared/`
- Fallbacks are provided for missing Bash features
- Graceful degradation for older Bash versions

## 🧪 **Testing**

Test Bash configurations with:
- Different Bash versions (4.x, 5.x)
- Various operating systems
- Interactive and non-interactive modes
- Different terminal emulators
