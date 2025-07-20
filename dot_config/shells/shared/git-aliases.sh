# This file is managed by chezmoi and maintained at https://github.com/levonk/dotfiles
# Git aliases (modularized from legacy sharedrc/aliases)
# Shell-neutral unless otherwise noted. See README for exceptions.

# Core git command shortcuts
alias gs='git status'
alias ga='git add'
alias gb='git branch'
alias gc='git commit'
alias gco='git checkout'
alias gd='git diff'
alias gl='git log --oneline --graph --decorate'
alias gp='git push'
alias gpl='git pull'
alias gcl='git clone'

# Git log with patch
alias glp='git log -p'

# Amend last commit (safe for shell use)
alias gca='git commit --amend --no-edit'

# Interactive rebase
alias grbi='git rebase -i'

# Show last commit
alias gshow='git show'

# Shell-specific: git stash pop (Zsh needs quoting)
if [ -n "$ZSH_VERSION" ]; then
  alias gsp='git stash pop --index'
else
  alias gsp='git stash pop'
fi
