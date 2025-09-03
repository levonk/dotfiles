# Shared Environment Variables

This directory contains **shell-neutral** environment variable configurations that work across all POSIX-compatible shells.

## 📁 **Purpose**

Environment files in this directory are loaded **early** in the shell startup process to establish the foundational environment for all subsequent configurations.

## 🔧 **Common Files**

### **`__xdg-env.sh`** - XDG Base Directory Compliance
Exports XDG environment variables according to the [XDG Base Directory Specification](https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html):

```bash
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
```

**Tools that use XDG:**
- [Git](https://git-scm.com/) - Uses `XDG_CONFIG_HOME` for global config
- [npm](https://www.npmjs.com/) - Uses `XDG_CONFIG_HOME` for npmrc
- [Docker](https://www.docker.com/) - Uses `XDG_CONFIG_HOME` for config
- [VS Code](https://code.visualstudio.com/) - Respects XDG directories

## ⚡ **Performance**

Environment files are:
- **Cached** for faster subsequent loads
- **Validated** before sourcing
- **Timed** for performance monitoring

## 🔗 **Related Tools**

**Environment Management:**
- [direnv](https://direnv.net/) - Per-directory environment variables
- [Environment Modules](http://modules.sourceforge.net/) - Dynamic environment modification

**XDG-Compliant Tools:**
- [bat](https://github.com/sharkdp/bat) - Uses `XDG_CONFIG_HOME`
- [fd](https://github.com/sharkdp/fd) - Uses `XDG_CONFIG_HOME`
- [ripgrep](https://github.com/BurntSushi/ripgrep) - Uses `XDG_CONFIG_HOME`

## 📝 **Adding New Environment Files**

1. Create `.sh` files with descriptive names
2. Use POSIX-compatible syntax
3. Include error handling and validation
4. Document environment variables in comments
5. Test across multiple shells

## 🔒 **Security**

- No sensitive data (passwords, tokens) should be stored here
- Use secure methods for secrets (environment files, vaults)
- Validate paths and values before export
