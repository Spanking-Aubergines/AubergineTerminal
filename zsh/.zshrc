# ~/.zshrc — managed by the dotfiles repository

# Keep interactive shell behavior explicit and minimal.
[[ -o interactive ]] || return

# History configuration.
HISTFILE="$HOME/.zsh_history"
HISTSIZE=10000
SAVEHIST=10000

setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
setopt SHARE_HISTORY
setopt HIST_FCNTL_LOCK

# Useful interactive behavior.
setopt AUTO_CD
setopt INTERACTIVE_COMMENTS

# Completion system.
autoload -Uz compinit
compinit

# Clear the screen with Ctrl+L.
bindkey -v
