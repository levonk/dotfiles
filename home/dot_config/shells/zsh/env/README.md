# Zsh Environment Variables

This directory contains **Zsh-specific** environment variable configurations that complement the shared environment variables.

## 📁 **Purpose**

Environment files here are loaded after shared environment variables and can:
- Override shared settings for Zsh-specific behavior
- Add Zsh-specific environment variables
- Configure Zsh history and shell options

## 🔧 **Common Zsh Environment Settings**

### **History Configuration**
```bash
# Zsh history settings
export HISTSIZE=10000
export SAVEHIST=10000
export HISTFILE="${XDG_STATE_HOME:-$HOME/.local/state}/zsh/history"

# Zsh history options
setopt HIST_IGNORE_DUPS      # Don't record duplicates
setopt HIST_IGNORE_ALL_DUPS  # Remove older duplicates
setopt HIST_SAVE_NO_DUPS     # Don't save duplicates
setopt HIST_IGNORE_SPACE     # Ignore commands starting with space
setopt SHARE_HISTORY         # Share history between sessions
setopt EXTENDED_HISTORY      # Save timestamp and duration
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
setopt AUTO_PUSHD           # automatically pushd directories
setopt PUSHD_IGNORE_DUPS    # don't push duplicate directories
```

### **Zsh-Specific Tool Configuration**
```bash
# Zsh completion system
export ZSH_COMPDUMP="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/compdump"

# Zsh configuration directory
export ZDOTDIR="${XDG_CONFIG_HOME:-$HOME/.config}/zsh"

# Zsh plugin directories
export ZSH_CUSTOM="${XDG_CONFIG_HOME:-$HOME/.config}/zsh/custom"
```

## 🔗 **Related Tools**

**Zsh History Tools:**
- [fzf](https://github.com/junegunn/fzf) - Fuzzy history search with Ctrl+R
- [zsh-history-substring-search](https://github.com/zsh-users/zsh-history-substring-search) - Fish-like history search
- [mcfly](https://github.com/cantino/mcfly) - Neural network history search

**Zsh Enhancement Tools:**
- [Oh My Zsh](https://ohmyz.sh/) - Zsh framework
- [Prezto](https://github.com/sorin-ionescu/prezto) - Configuration framework
- [Zinit](https://github.com/zdharma-continuum/zinit) - Plugin manager
- [zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions) - Fish-like autosuggestions
- [zsh-syntax-highlighting](https://github.com/zsh-users/zsh-syntax-highlighting) - Syntax highlighting

## ⚡ **Performance Considerations**

- Environment files are cached for faster subsequent loads
- Large history files may slow down shell startup
- Consider using history deduplication options
- Zsh completion system can be slow; consider lazy loading

## 📝 **Best Practices**

1. **History Management**: Use appropriate `HISTSIZE` and `SAVEHIST`
2. **XDG Compliance**: Store history and cache in XDG directories
3. **Shell Options**: Enable useful options like `EXTENDED_GLOB` and `AUTO_CD`
4. **Directory Creation**: Ensure required directories exist

## 🔒 **Security**

- Avoid storing sensitive data in history
- Use `HIST_IGNORE_SPACE` to ignore commands starting with space
- Set appropriate permissions on history files
- Consider using `HIST_NO_STORE` for sensitive commands
