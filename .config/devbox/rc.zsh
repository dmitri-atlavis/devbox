#
# Atlavis DevBox - Interactive Shell
#

# Zsh plugins
source ~/.zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
source ~/.zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# Autosuggestion settings
ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=20
ZSH_AUTOSUGGEST_USE_ASYNC=true

# Aliases
alias v=nvim
alias lg=lazygit
alias y=yazi
alias tmux='tmux -u'

# Terminal settings
export TERM=xterm-256color
export EDITOR=nvim
bindkey -v
source <(fzf --zsh)

# Starship prompt
eval "$(starship init zsh)"
