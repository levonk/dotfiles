# Shared Command Aliases

This directory contains **shell-neutral** command aliases that work across all POSIX-compatible shells.

## 📁 **Purpose**

Aliases in this directory provide:
- **Modern tool replacements** for traditional Unix commands
- **Convenience shortcuts** for common operations
- **Cross-shell compatibility** using POSIX syntax

## 🔧 **Common Files**

### **`modern-tools.sh`** - Modern CLI Tool Aliases
Replaces traditional Unix tools with modern, feature-rich alternatives:

```bash
# Modern replacements (if tools are installed)
alias ls='exa --color=auto --group-directories-first'
alias ll='exa -la --color=auto --group-directories-first'
alias cat='bat --paging=never'
alias grep='rg'
alias find='fd'
```

**Modern Tools:**
- [exa](https://github.com/ogham/exa) / [eza](https://github.com/eza-community/eza) - Modern `ls` with colors, icons, git status
- [bat](https://github.com/sharkdp/bat) - Modern `cat` with syntax highlighting and paging
- [fd](https://github.com/sharkdp/fd) - Modern `find` with intuitive syntax and speed
- [ripgrep](https://github.com/BurntSushi/ripgrep) - Modern `grep` with better performance and defaults
- [fzf](https://github.com/junegunn/fzf) - Fuzzy finder for interactive selection

### **`git-aliases.sh`** - Git Shortcuts
Common git command shortcuts:

```bash
alias g='git'
alias gst='git status'
alias gco='git checkout'
alias gaa='git add --all'
alias gcm='git commit -m'
alias gp='git push'
alias gl='git pull'
```

### **`safety-aliases.sh`** - Safe Command Defaults
Safer defaults for potentially destructive commands:

```bash
alias rm='rm -i'    # Interactive removal
alias cp='cp -i'    # Interactive copy
alias mv='mv -i'    # Interactive move
```

## ⚡ **Lazy Loading**

Aliases are registered for **lazy loading** with smart triggers:
- **`modern-tools.sh`**: Triggered by `ls`, `cat`, `grep`, `find` commands
- **`git-aliases.sh`**: Triggered by `git`, `g`, `gst`, `gco` commands
- **Other aliases**: Triggered by relevant commands

This means aliases are only loaded when you actually use the commands, improving shell startup performance.

## 🔗 **Tool Installation**

### **Package Managers**

**macOS (Homebrew):**
```bash
brew install exa bat fd ripgrep fzf
```

**Ubuntu/Debian:**
```bash
sudo apt install exa bat fd-find ripgrep fzf
```

**Arch Linux:**
```bash
sudo pacman -S exa bat fd ripgrep fzf
```

**Windows (Scoop):**
```bash
scoop install exa bat fd ripgrep fzf
```

### **Alternative Installation**

**Rust (Cargo):**
```bash
cargo install exa bat-cat fd-find ripgrep
```

**Node.js (npm):**
```bash
npm install -g @exa-community/exa
```

## 🔄 **Fallback Behavior**

Aliases include intelligent fallback to traditional tools:
```bash
# Example from modern-tools.sh
if command -v exa >/dev/null 2>&1; then
    alias ls='exa --color=auto --group-directories-first'
else
    alias ls='ls --color=auto'  # Fallback to traditional ls
fi
```

## 🎯 **Smart Detection**

The alias system:
- **Detects available tools** before creating aliases
- **Provides fallbacks** to traditional commands
- **Notifies users** about missing modern tools (optional)
- **Works without modern tools** installed

## 📝 **Adding New Aliases**

1. Create `.sh` files with descriptive names
2. Use POSIX-compatible syntax
3. Include tool detection and fallbacks:
   ```bash
   if command -v modern_tool >/dev/null 2>&1; then
       alias old_command='modern_tool'
   fi
   ```
4. Group related aliases logically
5. Document tool requirements and benefits

## 🔒 **Security Considerations**

- Avoid aliases that change command behavior dramatically
- Be cautious with aliases for security-sensitive commands
- Test aliases thoroughly before deployment
- Consider using functions instead of aliases for complex logic

## 🧪 **Testing**

Test aliases with:
- Different shells (bash, zsh, dash)
- With and without modern tools installed
- Various command-line scenarios
- Interactive and non-interactive shells
