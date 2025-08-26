# This file is managed by chezmoi (https://www.chezmoi.io/) and maintained at https://github.com/levonk/dotfiles

#------------------------------------------------------------------------------
# OhMyZsh Plugin Manager
#------------------------------------------------------------------------------
export ZSH="${XDG_CONFIG_HOME:-$HOME/.config}/shells/zsh/oh-my-zsh.zsh"
ZSH_THEME="robbyrussell"
plugins=(git)
source $ZSH/oh-my-zsh.sh

if [[ ! -f ${XDG_CONFIG_HOME:-$HOME/.config}/shells/zsh/prompts/prompt.zsh ]]; then
  echo "Installing Powerlevel10k..."
  git clone --depth=1 https://github.com/levonk/powerlevel10k.git ${XDG_CONFIG_HOME:-$HOME/.config}/shells/zsh/plugins/powerlevel10k
  echo 'source ${XDG_CONFIG_HOME:-$HOME/.config}/shells/zsh/plugins/powerlevel10k/powerlevel10k.zsh' >>! ${XDG_CONFIG_HOME:-$HOME/.config}/shells/zsh/prompts/prompt.zsh
fi
