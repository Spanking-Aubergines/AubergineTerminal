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

# Key bindings (vi mode; Ctrl+L clears the screen).
bindkey -v
bindkey '^L' clear-screen

# --- Zinit ---------------------------------------------------------------
ZINIT_HOME="${XDG_DATA_HOME:-$HOME/.local/share}/zinit"
if [[ ! -d "$ZINIT_HOME/zinit.git" ]]; then
    mkdir -p "$ZINIT_HOME"
    git clone --depth=1 https://github.com/zdharma-continuum/zinit.git \
        "$ZINIT_HOME/zinit.git"
fi
source "$ZINIT_HOME/zinit.git/zinit.zsh"

# Plugins (Turbo mode defers loading until after the prompt appears).
zinit wait lucid light-mode for \
    atinit"zicompinit; zicdreplay" \
        zdharma-continuum/fast-syntax-highlighting \
    atload"_zsh_autosuggest_start" \
        zsh-users/zsh-autosuggestions \
    blockf atpull'zinit creinstall -q .' \
        zsh-users/zsh-completions \
    atload'
        bindkey -M viins "\C-p" history-substring-search-up
        bindkey -M viins "\C-n" history-substring-search-down
        bindkey -M vicmd "k" history-substring-search-up
        bindkey -M vicmd "j" history-substring-search-down
    ' zsh-users/zsh-history-substring-search
