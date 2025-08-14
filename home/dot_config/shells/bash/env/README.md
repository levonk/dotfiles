# Bash Environment Variables

This directory contains **Bash-specific** environment variable configurations that complement the shared environment variables.

## 📁 **Purpose**

Environment files here are loaded after shared environment variables and can:
- Override shared settings for Bash-specific behavior
- Add Bash-specific environment variables
- Configure Bash history and shell options

## 🔧 **Common Bash Environment Settings**

### **History Configuration**
```bash
# Bash history settings
export HISTSIZE=10000
export HISTFILESIZE=20000
export HISTCONTROL=ignoredups:erasedups
export HISTTIMEFORMAT="%Y-%m-%d %H:%M:%S "
export HISTFILE="${XDG_STATE_HOME:-$HOME/.local/state}/bash/history"

# Append to history file, don't overwrite
shopt -s histappend
```

### **Shell Options**
```bash
# Useful Bash options
shopt -s autocd        # cd by typing directory name
shopt -s cdspell       # correct minor spelling errors in cd
shopt -s checkwinsize  # update LINES and COLUMNS after each command
shopt -s globstar      # enable ** for recursive globbing
shopt -s nocaseglob    # case-insensitive globbing
```

### **Bash-Specific Tool Configuration**
```bash
# Bash completion
export BASH_COMPLETION_USER_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/bash/bash_completion"

# Readline configuration
export INPUTRC="${XDG_CONFIG_HOME:-$HOME/.config}/readline/inputrc"
```

## 🔗 **Related Tools**

**Bash History Tools:**
- [fzf](https://github.com/junegunn/fzf) - Fuzzy history search with Ctrl+R
- [hstr](https://github.com/dvorka/hstr) - Bash history suggest box
- [mcfly](https://github.com/cantino/mcfly) - Neural network history search

**Bash Enhancement Tools:**
- [bash-completion](https://github.com/scop/bash-completion) - Programmable completion
- [bash-it](https://github.com/Bash-it/bash-it) - Bash framework
- [liquidprompt](https://github.com/nojhan/liquidprompt) - Adaptive prompt

## ⚡ **Performance Considerations**

- Environment files are cached for faster subsequent loads
- Large history files may slow down shell startup
- Consider using `HISTCONTROL=ignoredups:erasedups` to reduce history size

## 📝 **Best Practices**

1. **History Management**: Use appropriate `HISTSIZE` and `HISTFILESIZE`
2. **XDG Compliance**: Store history in `XDG_STATE_HOME`
3. **Shell Options**: Enable useful options like `globstar` and `autocd`
4. **Error Handling**: Include validation for directory creation

## 🔒 **Security**

- Avoid storing sensitive data in history
- Consider using `HISTCONTROL=ignorespace` to ignore commands starting with space
- Set appropriate permissions on history files
