# Zsh-Specific Configurations

This directory contains configurations specific to the **Zsh shell** that complement the shared shell configurations.

## 🚀 **Entry Point**

### **`entrypoint.zsh`** - Zsh Entry Point
The main entry point for Zsh sessions that delegates to the optimized `entrypointrc.sh`:

```bash
# In ~/.zshrc
source ~/.config/shells/zsh/entrypoint.zsh
```

This entry point automatically:
- Detects Zsh environment
- Loads Zsh-specific configurations with performance optimizations
- Provides caching, lazy loading, and timing for Zsh configs

## 📁 **Subdirectories**

### **`env/`** - Zsh Environment Variables
Zsh-specific environment variables and exports:
- Zsh history settings (`HISTSIZE`, `SAVEHIST`, `HISTFILE`)
- Zsh-specific tool configurations
- Shell options and behavior settings

### **`util/`** - Zsh Utility Functions
Zsh-specific utility functions that leverage Zsh features:
- Advanced parameter expansion
- Zsh associative arrays and hash tables
- Zsh-specific globbing and pattern matching
- Widget functions for line editing

### **`aliases/`** - Zsh-Specific Aliases
Aliases that use Zsh-specific features or syntax:
- Zsh history manipulation
- Zsh-specific shortcuts
- Global aliases and suffix aliases

### **`completions/`** - Zsh Tab Completion
Zsh completion scripts using the powerful [Zsh completion system](https://zsh.sourceforge.io/Doc/Release/Completion-System.html):
- Custom command completions
- Tool-specific completion scripts
- Completion functions and widgets

### **`prompts/`** - Zsh Prompt Configurations
Zsh-specific prompt configurations:
- Prompt themes using Zsh prompt system
- Git integration for prompts
- Custom prompt functions

## 🔧 **Zsh-Specific Features**

### **History Configuration**
```bash
# Common Zsh history settings
export HISTSIZE=10000
export SAVEHIST=10000
export HISTFILE="${XDG_STATE_HOME:-$HOME/.local/state}/zsh/history"
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_SAVE_NO_DUPS
setopt SHARE_HISTORY
```

### **Shell Options**
```bash
# Useful Zsh options
setopt AUTO_CD              # cd by typing directory name
setopt CORRECT              # command correction
setopt EXTENDED_GLOB        # extended globbing patterns
setopt GLOB_DOTS            # include dotfiles in globbing
setopt NO_CASE_GLOB         # case-insensitive globbing
setopt NUMERIC_GLOB_SORT    # sort numerically when possible
```

### **Completion System**
```bash
# Initialize Zsh completion system
autoload -Uz compinit
compinit

# Completion styles
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
```

## 🔗 **Zsh-Specific Tools**

**Frameworks:**
- [Oh My Zsh](https://ohmyz.sh/) - Popular Zsh framework with plugins and themes
- [Prezto](https://github.com/sorin-ionescu/prezto) - Configuration framework for Zsh
- [Zinit](https://github.com/zdharma-continuum/zinit) - Flexible Zsh plugin manager
- [Antibody](https://getantibody.github.io/) - Fast Zsh plugin manager

**Prompt Tools:**
- [Starship](https://starship.rs/) - Cross-shell prompt (excellent Zsh support)
- [Powerlevel10k](https://github.com/romkatv/powerlevel10k) - Fast and flexible Zsh theme
- [Pure](https://github.com/sindresorhus/pure) - Minimal and fast Zsh prompt
- [Spaceship](https://github.com/spaceship-prompt/spaceship-prompt) - Minimalistic Zsh prompt

**Plugins:**
- [zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions) - Fish-like autosuggestions
- [zsh-syntax-highlighting](https://github.com/zsh-users/zsh-syntax-highlighting) - Syntax highlighting
- [zsh-history-substring-search](https://github.com/zsh-users/zsh-history-substring-search) - History search
- [fzf-zsh](https://github.com/junegunn/fzf) - Fuzzy finder integration

## ⚡ **Performance Features**

Zsh-specific configurations benefit from:
- **Caching** for frequently sourced completion scripts
- **Lazy loading** for optional Zsh modules and plugins
- **Performance timing** for Zsh-specific startup operations
- **Redundancy protection** to prevent double-loading

## 📦 **Installation Requirements**

**Zsh Version:**
- Minimum: Zsh 5.0+ (for modern features)
- Recommended: Zsh 5.8+ (latest features and performance improvements)

**Check Zsh version:**
```bash
zsh --version
echo $ZSH_VERSION
```

## 📝 **Adding Zsh-Specific Configurations**

1. **Environment variables**: Add to `env/` directory
2. **Functions**: Add to `util/` directory (use Zsh-specific features freely)
3. **Aliases**: Add to `aliases/` directory (can use Zsh syntax, global aliases)
4. **Completions**: Add to `completions/` directory (use Zsh completion format)
5. **Prompts**: Add to `prompts/` directory (use Zsh prompt system)

### **Example Zsh Function**
```bash
# In util/zsh-helpers.sh
# Zsh-specific function using parameter expansion
extract_extension() {
    local file="$1"
    echo "${file:e}"  # Zsh parameter expansion for extension
}

# Zsh widget function
widget-accept-line() {
    # Custom logic before accepting line
    zle accept-line
}
zle -N widget-accept-line
bindkey '^M' widget-accept-line
```

### **Example Global Alias**
```bash
# In aliases/zsh-global.sh
# Zsh global aliases (work anywhere in command line)
alias -g L='| less'
alias -g G='| grep'
alias -g H='| head'
alias -g T='| tail'
```

## 🔄 **Compatibility**

While this directory contains Zsh-specific configurations:
- Shared configurations are still loaded from `../shared/`
- Fallbacks are provided for missing Zsh features
- Graceful degradation for older Zsh versions

## 🧪 **Testing**

Test Zsh configurations with:
- Different Zsh versions (5.x)
- Various operating systems
- Interactive and non-interactive modes
- Different terminal emulators
- With and without Zsh frameworks
