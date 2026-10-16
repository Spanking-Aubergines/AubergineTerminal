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

# bat (used as pager and cat replacement when available).
# Debian ships the binary as "batcat".
BAT_BIN=""
if command -v bat >/dev/null 2>&1; then
    BAT_BIN="bat"
elif command -v batcat >/dev/null 2>&1; then
    BAT_BIN="batcat"
fi
if [[ -n "$BAT_BIN" ]]; then
    export BAT_THEME="ansi"
    export MANPAGER="sh -c 'col -bx | $BAT_BIN -l man -p'"
    export MANROFFOPT="-c"
fi
unset BAT_BIN

# Useful interactive behavior.
setopt AUTO_CD
setopt INTERACTIVE_COMMENTS

# Completion system.
autoload -Uz compinit
compinit

# Key bindings (vi mode; Ctrl+L clears the screen).
bindkey -v
bindkey '^L' clear-screen

# Sibling files, resolved relative to this .zshrc so the repo can live anywhere.
DOTFILES_ZSH_DIR="${${(%):-%x}:A:h}"
[[ -f "$DOTFILES_ZSH_DIR/.config/zsh/aliases.zsh" ]]   && source "$DOTFILES_ZSH_DIR/.config/zsh/aliases.zsh"
[[ -f "$DOTFILES_ZSH_DIR/.config/zsh/functions.zsh" ]] && source "$DOTFILES_ZSH_DIR/.config/zsh/functions.zsh"
unset DOTFILES_ZSH_DIR

# --- Zinit ---------------------------------------------------------------
ZINIT_HOME="${XDG_DATA_HOME:-$HOME/.local/share}/zinit"
if [[ ! -d "$ZINIT_HOME/zinit.git" ]]; then
    mkdir -p "$ZINIT_HOME"
    git clone --depth=1 https://github.com/zdharma-continuum/zinit.git \
        "$ZINIT_HOME/zinit.git"
fi
source "$ZINIT_HOME/zinit.git/zinit.zsh"

# Vi mode (loads first; it overwrites keybindings from other plugins).
zinit ice depth=1
zinit light jeffreytse/zsh-vi-mode

# Plugins (Turbo mode defers loading until after the prompt appears).
zinit wait lucid light-mode for \
    atinit"zicompinit; zicdreplay" \
        zdharma-continuum/fast-syntax-highlighting \
    atload"_zsh_autosuggest_start" \
        zsh-users/zsh-autosuggestions \
    atload'
        bindkey -M viins "\C-p" history-substring-search-up
        bindkey -M viins "\C-n" history-substring-search-down
        bindkey -M vicmd "\C-p" history-substring-search-up
        bindkey -M vicmd "\C-n" history-substring-search-down
    ' zsh-users/zsh-history-substring-search \
    atload'
        source <(fzf --zsh)
        export FZF_DEFAULT_OPTS="--height 40% --layout=reverse --border"
    ' hlissner/zsh-autopair \
    atload'
        export YSU_MESSAGE_POSITION="after"
    ' MichaelAquilina/zsh-you-should-use \
    blockf atpull'zinit creinstall -q .' \
        zsh-users/zsh-completions \
    atload'
        zstyle ":completion:*" menu no
        zstyle ":fzf-tab:*" fzf-flags "--height=40%" "--layout=reverse"
    ' Aloxaf/fzf-tab \
    atload'
        bindkey "\e\e" sudo-command-line
    ' OMZP::sudo

# Semantic man-page colorizer (replaces MANPAGER with a semantic colorizer).
zinit light diverdale/colored-man-pages-plus

# Real-time type-ahead completion (loads before autosuggestions and fzf-tab).

# Fish-style auto-expanding abbreviations.
zinit light olets/zsh-abbr

# Pick a theme: dracula, catppuccin, gruvbox, tokyonight, light, ansi.
export COLORED_MAN_THEME=catppuccin

# zoxide (smarter cd). Provides z and zi.
if command -v zoxide >/dev/null 2>&1; then
    eval "$(zoxide init zsh)"
fi

# Machine-specific overrides (not tracked by this repository).
[[ -f "$HOME/.zshrc.local" ]] && source "$HOME/.zshrc.local"

# Prompt (Starship; loads last so it wins the prompt).
# >>> Persistent Starship theme >>>
_starship_theme="voight"
if [[ -r "$HOME/.config/starship-theme" ]]; then
    _saved_theme="$(<"$HOME/.config/starship-theme")"
    if [[ -n "$_saved_theme" && -r "$HOME/.dotfiles/zsh/.config/starship/themes/$_saved_theme.toml" ]]; then
        _starship_theme="$_saved_theme"
    fi
fi
export STARSHIP_CONFIG="$HOME/.dotfiles/zsh/.config/starship/themes/$_starship_theme.toml"
unset _starship_theme _saved_theme
# <<< Persistent Starship theme <<<

eval "$(starship init zsh)"
