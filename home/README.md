# Dotfiles Home Inventory

This directory is managed by chezmoi as part of the dotfiles repo:

- Repository: <https://github.com/levonk/dotfiles>

Below is a categorized index of everything under `home/` with links to the managed paths.

## Chezmoi Configuration

- [`.chezmoi.toml.tmpl`](./.chezmoi.toml.tmpl) — Chezmoi main config template (Tool: <https://www.chezmoi.io/>)
- [`.chezmoiexternal.toml`](./.chezmoiexternal.toml) — External resources managed by chezmoi (Tool: <https://www.chezmoi.io/>)
- [`.chezmoiignore.tmpl`](./.chezmoiignore.tmpl) — Paths ignored by chezmoi (Tool: <https://www.chezmoi.io/>)
- [`.chezmoiremove`](./.chezmoiremove) — Files/paths to remove on apply (Tool: <https://www.chezmoi.io/>)
- [`./.chezmoiscripts/`](./.chezmoiscripts/) — Chezmoi hook scripts (Tool: <https://www.chezmoi.io/>)
- [`./.chezmoitemplates/`](./.chezmoitemplates/) — Shared templates for config files (Tool: <https://www.chezmoi.io/>)
- [`./dot_chezmoidata.yaml.tmpl`](./dot_chezmoidata.yaml.tmpl) — Data variables used by templates (Tool: <https://www.chezmoi.io/>)

## Core Dotfiles (in $HOME)

- [`./dot_Xmodmap`](./dot_Xmodmap) — X keyboard mappings (Tool: <https://wiki.archlinux.org/title/Xmodmap>)
- [`./dot_Xresources`](./dot_Xresources) — X11/URxvt/terminal resource settings (Tool: <https://wiki.archlinux.org/title/X_resources>)
- [`./dot_ackrc`](./dot_ackrc) — ack search tool configuration (Tool: <https://beyondgrep.com/>)
- [`./dot_bash_env`](./dot_bash_env) — Bash environment variables (Tool: <https://www.gnu.org/software/bash/>)
- [`./dot_bash_login`](./dot_bash_login) — Bash login initialization (Doc: <https://www.gnu.org/software/bash/manual/bash.html#Bash-Startup-Files>)
- [`./dot_bash_profile`](./dot_bash_profile) — Bash profile for login shells
- [`./dot_cssh_clusters`](./dot_cssh_clusters) — Cluster SSH host definitions
- [`./dot_csshrc`](./dot_csshrc) — Cluster SSH runtime config
- [`./dot_ctags`](./dot_ctags) — Universal Ctags configuration (Tool: <https://ctags.io/>)
- [`./dot_editorconfig`](./dot_editorconfig) — EditorConfig settings (Tool: <https://editorconfig.org/>)
- [`./dot_editorconfig-checker.json`](./dot_editorconfig-checker.json) — EditorConfig checker tool settings (Tool: <https://github.com/editorconfig-checker/editorconfig-checker>)
- [`./dot_editrc`](./dot_editrc) — ed/ex/vi editrc settings (Tool: <https://man.freebsd.org/cgi/man.cgi?query=editrc>)
- [`./dot_golangci.yml`](./dot_golangci.yml) — golangci-lint configuration (Tool: <https://golangci-lint.run/>)
- [`./dot_jstatd.all.policy`](./dot_jstatd.all.policy) — Java jstatd security policy (Tool: <https://docs.oracle.com/javase/8/docs/technotes/tools/unix/jstatd.html>)
- [`./dot_mailcap`](./dot_mailcap) — MIME type handler mappings (Spec: <https://en.wikipedia.org/wiki/Mailcap>)
- [`./dot_markdownlint-cli2.yaml`](./dot_markdownlint-cli2.yaml) — markdownlint-cli2 rules (Tool: <https://github.com/DavidAnson/markdownlint-cli2>)
- [`./dot_mavenrc`](./dot_mavenrc) — Maven runtime options (Tool: <https://maven.apache.org/>)
- [`./dot_profile`](./dot_profile) — POSIX shell profile (Spec: <https://pubs.opengroup.org/onlinepubs/9699919799/>)
- [`./dot_screenrc`](./dot_screenrc) — GNU screen configuration (Tool: <https://www.gnu.org/software/screen/>)
- [`./dot_tmux.conf`](./dot_tmux.conf) — tmux configuration (Tool: <https://github.com/tmux/tmux>)
- [`./dot_xinitrc`](./dot_xinitrc) — X session init script (Doc: <https://wiki.archlinux.org/title/Xinit>)
- [`./dot_xprofile`](./dot_xprofile) — X session environment/profile (Doc: <https://wiki.archlinux.org/title/Xprofile>)
- [`./dot_yarnrc.yml`](./dot_yarnrc.yml) — Yarn package manager config (Tool: <https://yarnpkg.com/>)
- [`./dot_zshenv`](./dot_zshenv) — Zsh environment variables (Tool: <https://www.zsh.org/>)
- [`./.jstatd.all.policy`](./.jstatd.all.policy) — jstatd policy (hidden)

## Application and System Data

- [`./AppData/`](./AppData/) (Windows) — Windows user config subtree
  - [`./AppData/Local/`](./AppData/Local/) — Machine-local app data
  - [`./AppData/Roaming/`](./AppData/Roaming/) — Roaming user app data
- [`./Library/`](./Library/) (macOS) — macOS user Library subtree
  - [`./Library/Application Support/`](./Library/Application%20Support/) — App support data
- [`./dot_local/`](./dot_local/) — ~/.local tree (bin, share, etc.)
- [`./dot_m2/`](./dot_m2/) — Maven ~/.m2 settings
- [`./dot_mvn/`](./dot_mvn/) — Maven wrapper/config

## Editors and IDEs

- [`./dot_config/emacs/`](./dot_config/emacs/) — Emacs configuration (Tool: <https://www.gnu.org/software/emacs/>)
- [`./dot_config/nvim/`](./dot_config/nvim/) — Neovim configuration (Tool: <https://neovim.io/>)
- [`./dot_config/Code/`](./dot_config/Code/) — VS Code settings/snippets (Tool: <https://code.visualstudio.com/>)
- [`./dot_config/indent-pro/`](./dot_config/indent-pro/) — Indent-Pro settings
- [`./dot_editorconfig`](./dot_editorconfig) — EditorConfig rules (shared)

## Terminals and Multiplexers

- [`./dot_config/alacritty/`](./dot_config/alacritty/) — Alacritty terminal config (Tool: <https://alacritty.org/>)
- [`./dot_config/foot/`](./dot_config/foot/) — foot terminal config (Tool: <https://codeberg.org/dnkl/foot>)
- [`./dot_config/kitty/`](./dot_config/kitty/) — Kitty terminal config (Tool: <https://sw.kovidgoyal.net/kitty/>)
- [`./dot_config/lxterminal/`](./dot_config/lxterminal/) — LXTerminal config (Tool: <https://wiki.lxde.org/en/LXTerminal>)
- [`./dot_config/qterminal.org/`](./dot_config/qterminal.org/) — QTerminal config (Tool: <https://github.com/lxqt/qterminal>)
- [`./dot_config/terminator/`](./dot_config/terminator/) — Terminator config (Tool: <https://github.com/gnome-terminator/terminator>)
- [`./dot_config/wezterm/`](./dot_config/wezterm/) — WezTerm config (Tool: <https://wezfurlong.org/wezterm/>)
- [`./dot_config/xfce4/`](./dot_config/xfce4/) — Xfce4 terminal/desktop settings (Tool: <https://www.xfce.org/>)
- [`./dot_config/zellij/`](./dot_config/zellij/) — Zellij multiplexer config (Tool: <https://zellij.dev/>)
- [`./dot_byobu/`](./dot_byobu/) — Byobu profile/config (Tool: <https://www.byobu.org/>)
- [`./dot_tmux.conf`](./dot_tmux.conf) — tmux configuration (Tool: <https://github.com/tmux/tmux>)

## Shells, Prompts, and History Tools

- [`./dot_config/fish/`](./dot_config/fish/) — Fish shell config (Tool: <https://fishshell.com/>)
- [`./dot_config/shells/`](./dot_config/shells/) — Shared shell setup (aliases, funcs)
- [`./dot_config/starship.toml`](./dot_config/starship.toml) — Starship prompt config (Tool: <https://starship.rs/>)
- [`./dot_config/atuin/`](./dot_config/atuin/) — Atuin shell history sync (Tool: <https://atuin.sh/>)
- [`./dot_zshenv`](./dot_zshenv) — Zsh environment variables
- [`./dot_bash_env`](./dot_bash_env) — Bash environment variables
- [`./dot_bash_login`](./dot_bash_login) — Bash login init
- [`./dot_bash_profile`](./dot_bash_profile) — Bash profile
- [`./dot_config/inputrc/`](./dot_config/inputrc/) — Readline/input settings (Tool: <https://tiswww.case.edu/php/chet/readline/rltop.html>)

## Browsers

- [`./dot_config/BraveSoftware/`](./dot_config/BraveSoftware/) — Brave browser settings (Tool: <https://brave.com/>)
- [`./dot_config/chromium/`](./dot_config/chromium/) — Chromium settings (Tool: <https://www.chromium.org/>)
- [`./dot_config/google-chrome/`](./dot_config/google-chrome/) — Google Chrome settings (Tool: <https://www.google.com/chrome/>)
- [`./dot_config/google-chrome-beta/`](./dot_config/google-chrome-beta/) — Chrome Beta settings (Tool: <https://www.google.com/chrome/beta/>)
- [`./dot_config/google-chrome-for-testing/`](./dot_config/google-chrome-for-testing/) — Chrome for Testing profile (Doc: <https://developer.chrome.com/docs/web-platform/chrome-for-testing/>)
- [`./dot_config/google-chrome-unstable/`](./dot_config/google-chrome-unstable/) — Chrome Unstable settings (Tool: <https://www.google.com/chrome/canary/>)
- [`./dot_config/microsoft-edge/`](./dot_config/microsoft-edge/) — Microsoft Edge settings (Tool: <https://www.microsoft.com/edge>)
- [`./dot_config/opera/`](./dot_config/opera/) — Opera settings (Tool: <https://www.opera.com/>)
- [`./dot_config/opera-gx/`](./dot_config/opera-gx/) — Opera GX settings (Tool: <https://www.opera.com/gx>)
- [`./dot_config/vivaldi/`](./dot_config/vivaldi/) — Vivaldi settings (Tool: <https://vivaldi.com/>)
- [`./dot_config/firefox-profile-template/`](./dot_config/firefox-profile-template/) — Firefox profile template (Tool: <https://www.mozilla.org/firefox/>)
- [`./dot_config/browsers/`](./dot_config/browsers/) — Shared browser configs
- [`./dot_librewolf/`](./dot_librewolf/) — LibreWolf settings (Tool: <https://librewolf.net/>)

## Developer Tooling and VCS

- [`./dot_config/git/`](./dot_config/git/) — Git config, includes, attributes (Tool: <https://git-scm.com/>)
- [`./dot_config/ctags/`](./dot_config/ctags/) — ctags language/regex settings (Tool: <https://ctags.io/>)
- [`./dot_ctags`](./dot_ctags) — ctags user config
- [`./dot_golangci.yml`](./dot_golangci.yml) — GolangCI-Lint rules
- [`./dot_markdownlint-cli2.yaml`](./dot_markdownlint-cli2.yaml) — Markdown lint rules
- [`./dot_editorconfig-checker.json`](./dot_editorconfig-checker.json) — EditorConfig checker config
- [`./dot_config/tig/`](./dot_config/tig/) — tig (ncurses Git UI) config (Tool: <https://jonas.github.io/tig/>)
- [`./dot_config/yamllint/`](./dot_config/yamllint/) — YAML lint config (Tool: <https://yamllint.readthedocs.io/>)
- [`./dot_config/templates/`](./dot_config/templates/) — Snippets/templates
- [`./dot_codeium/`](./dot_codeium/) — Codeium client settings (Tool: <https://codeium.com/>)
- [`./dot_claude-code-router/`](./dot_claude-code-router/) — Claude router settings (Tool: <https://www.anthropic.com/claude>)

## Programming Languages, Runtimes, and Package Managers

- [`./dot_config/mise/`](./dot_config/mise/) — mise/asdf-style runtime manager config (Tool: <https://mise.jdx.dev/>)
- [`./dot_config/sdkman/`](./dot_config/sdkman/) — SDKMAN runtime manager config (Tool: <https://sdkman.io/>)
- [`./dot_config/npm/`](./dot_config/npm/) — npm configuration (Tool: <https://www.npmjs.com/>)
- [`./dot_config/pnpm/`](./dot_config/pnpm/) — pnpm configuration (Tool: <https://pnpm.io/>)
- [`./dot_yarnrc.yml`](./dot_yarnrc.yml) — Yarn configuration (Tool: <https://yarnpkg.com/>)
- [`./dot_m2/`](./dot_m2/) — Maven settings and caches (Tool: <https://maven.apache.org/>)
- [`./dot_mvn/`](./dot_mvn/) — Maven wrapper configuration (Tool: <https://maven.apache.org/wrapper/>)
- [`./dot_config/tealdeer/`](./dot_config/tealdeer/) — tldr client (tealdeer) config (Tool: <https://dbrgn.github.io/tealdeer/>)
- [`./dot_config/ripgrep/`](./dot_config/ripgrep/) — ripgrep defaults and globs (Tool: <https://github.com/BurntSushi/ripgrep>)

## Databases and Data Tools

- [`./dot_config/psql/`](./dot_config/psql/) — PostgreSQL client (.psqlrc, includes) (Tool: <https://www.postgresql.org/docs/current/app-psql.html>)
- [`./dot_config/mongosh/`](./dot_config/mongosh/) — MongoDB shell config (Tool: <https://www.mongodb.com/docs/mongodb-shell/>)

## UI, Fonts, and Desktop

- [`./dot_config/fontconfig/`](./dot_config/fontconfig/) — Fontconfig rules and aliases (Tool: <https://www.freedesktop.org/wiki/Software/fontconfig/>)
- [`./dot_config/gtk-3.0/`](./dot_config/gtk-3.0/) — GTK 3 theming and settings (Tool: <https://www.gtk.org/>)
- [`./dot_config/gtk-4.0/`](./dot_config/gtk-4.0/) — GTK 4 theming and settings (Tool: <https://www.gtk.org/>)
- [`./dot_config/dunst/`](./dot_config/dunst/) — Dunst notification daemon config (Tool: <https://dunst-project.org/>)
- [`./dot_config/mako/`](./dot_config/mako/) — Mako notifications config (Tool: <https://github.com/emersion/mako>)
- [`./dot_Xresources`](./dot_Xresources) — X/terminal color and font settings (Doc: <https://wiki.archlinux.org/title/X_resources>)
- [`./dot_xinitrc`](./dot_xinitrc) — X session startup (Doc: <https://wiki.archlinux.org/title/Xinit>)
- [`./dot_xprofile`](./dot_xprofile) — X session environment (Doc: <https://wiki.archlinux.org/title/Xprofile>)
- [`./dot_config/keyboard/`](./dot_config/keyboard/) — Keymaps/keyboard options (Doc: <https://wiki.archlinux.org/title/X_keyboard_extension>)

## Networking and CLI Utilities

- [`./dot_config/curl/`](./dot_config/curl/) — curl defaults (TLS, headers, etc.) (Tool: <https://curl.se/>)
- [`./dot_config/bin/`](./dot_config/bin/) — Small helper scripts in PATH
- [`./dot_config/filelists/`](./dot_config/filelists/) — Generated/managed file lists
- [`./dot_config/ai/`](./dot_config/ai/) — AI tool configuration
- [`./dot_config/cursor/`](./dot_config/cursor/) — Cursor editor config (Tool: <https://cursor.sh/>)
- [`./dot_config/obsidian-mcp-rest/`](./dot_config/obsidian-mcp-rest/) — Obsidian MCP REST settings (Tool: <https://obsidian.md/>)
- [`./dot_ssh/`](./dot_ssh/) — SSH client configuration and keys (Tool: <https://www.openssh.com/>)
- [`./dot_cssh_clusters`](./dot_cssh_clusters) — cssh cluster definitions (Tool: <https://clusterssh.sourceforge.net/>)
- [`./dot_csshrc`](./dot_csshrc) — cssh runtime config (Tool: <https://clusterssh.sourceforge.net/>)

## Mail, Screen, and Misc

- [`./dot_mailcap`](./dot_mailcap) — MIME handlers for mail/CLI tools (Spec: <https://en.wikipedia.org/wiki/Mailcap>)
- [`./dot_screenrc`](./dot_screenrc) — GNU screen configuration (Tool: <https://www.gnu.org/software/screen/>)

---
If something is missing or miscategorized, update this file alongside the relevant paths in `home/`.
