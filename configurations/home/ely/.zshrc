# Powerlevel10k instant prompt — deve ficar no topo
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Oh My Zsh
export ZSH="/usr/share/oh-my-zsh"

plugins=(git)

source "$ZSH/oh-my-zsh.sh"

# Powerlevel10k instalado pelo sistema (pacman)
source /usr/share/zsh-theme-powerlevel10k/powerlevel10k.zsh-theme

# Plugins instalados pelo sistema
source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# PATH
export PATH="$HOME/.local/bin:$PATH"
export PATH="$PATH:$HOME/.lmstudio/bin"

# Aliases
alias ls='eza -lh --group-directories-first --icons=auto'
alias lsa='ls -a'
alias lt='eza --tree --level=2 --long --icons --git'
alias lta='lt -a'
alias ll='eza -lah --group-directories-first --icons=auto'

# P10k config
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh


export PATH=$PATH:/home/ely/.spicetify
