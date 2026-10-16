# Shell aliases. Sourced from .zshrc.

# Navigation
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

# Listing
if command -v eza >/dev/null 2>&1; then
    alias ls='eza --group-directories-first'
    alias ll='eza -l --group-directories-first'
    alias la='eza -la --group-directories-first'
    alias lt='eza --tree --level=2'
else
    alias ls='ls --color=auto'
    alias ll='ls -lh'
    alias la='ls -lah'
fi

# Git shortcuts
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gd='git diff'
alias gl='git log --oneline --graph --decorate'
alias gco='git checkout'
alias gb='git branch'

# Grep / find replacements
if command -v rg >/dev/null 2>&1; then
    alias grep='rg'
fi
# Debian ships fd as "fdfind"; Arch ships it as "fd".
if command -v fd >/dev/null 2>&1; then
    alias find='fd'
elif command -v fdfind >/dev/null 2>&1; then
    alias find='fdfind'
fi

# cat replacement. Debian ships bat as "batcat".
if command -v bat >/dev/null 2>&1; then
    alias cat='bat --style=plain --paging=never'
    alias catp='bat'
elif command -v batcat >/dev/null 2>&1; then
    alias cat='batcat --style=plain --paging=never'
    alias catp='batcat'
fi
