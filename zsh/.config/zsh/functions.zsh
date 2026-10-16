# Shell functions. Sourced from .zshrc.

# mkdir + cd in one step.
mkcd() {
    [[ -n "${1:-}" ]] || { printf 'usage: mkcd DIR\n' >&2; return 1; }
    mkdir -p -- "$1" && cd -- "$1"
}

# Extract almost any archive.
extract() {
    if [[ ! -f "${1:-}" ]]; then
        printf 'usage: extract FILE\n' >&2
        return 1
    fi

    local file="$1"
    local tool
    local -a args

    case "$file" in
        *.tar.bz2|*.tbz2) tool=tar; args=(xjf "$file") ;;
        *.tar.gz|*.tgz)   tool=tar; args=(xzf "$file") ;;
        *.tar.xz|*.txz)   tool=tar; args=(xJf "$file") ;;
        *.tar)            tool=tar; args=(xf "$file") ;;
        *.bz2)            tool=bunzip2 ;;
        *.gz)             tool=gunzip ;;
        *.zip)            tool=unzip ;;
        *.7z)             tool=7z ;;
        *) printf 'Unknown archive type: %s\n' "$file" >&2; return 1 ;;
    esac

    if ! command -v "$tool" >/dev/null 2>&1; then
        printf 'Required extraction tool not found: %s\n' "$tool" >&2
        return 127
    fi

    if [[ "$tool" == tar ]]; then
        command tar "${args[@]}"
    else
        command "$tool" "$file"
    fi
}

# Show the top N entries by CPU/memory (default 10).
topcpu() { ps -eo pid,ppid,cmd,%cpu --sort=-%cpu | head -n "${1:-10}"; }
topmem() { ps -eo pid,ppid,cmd,%mem --sort=-%mem | head -n "${1:-10}"; }

# Quick port lookup: what's listening on PORT?
port() {
    if [[ ! "${1:-}" =~ ^[0-9]+$ ]] ||
       (( 10#$1 < 1 || 10#$1 > 65535 )); then
        printf 'usage: port PORT (1-65535)\n' >&2
        return 2
    fi

    ss -tulpn 2>/dev/null | command grep -E ":${1}([^0-9]|$)" ||
        printf 'Nothing listening on port %s\n' "$1"
}

# Yazi file manager
function y() {
    local cwd_file
    cwd_file="$(mktemp)" || return 1

    yazi --cwd-file="$cwd_file" "$@"
    local exit_status=$?

    if [[ -s "$cwd_file" ]]; then
        local new_dir
        new_dir="$(<"$cwd_file")"
        if [[ -n "$new_dir" && -d "$new_dir" ]]; then
            builtin cd -- "$new_dir"
        fi
    fi

    command rm -f -- "$cwd_file"
    return "$exit_status"
}


# >>> Oh My Posh theme selector >>>
function prompt-theme() {
    local theme_dir="${DOTFILES_ZSH_DIR:-$HOME/.dotfiles/zsh}/.config/ohmyposh/themes"
    local selection_file="$HOME/.config/ohmyposh-theme"
    local theme_file theme
    local -a theme_names

    if [[ ! -d "$theme_dir" ]]; then
        print -u2 "Oh My Posh themes directory not found: $theme_dir"
        return 1
    fi

    for theme_file in "$theme_dir"/*.omp.json(N); do
        theme_names+=("${${theme_file:t}:r:r}")
    done

    if (( ${#theme_names[@]} == 0 )); then
        print -u2 "No Oh My Posh themes found."
        return 1
    fi

    print "\nAvailable Oh My Posh themes:"
    select theme in "${theme_names[@]}"; do
        if [[ -z "$theme" ]]; then
            print "Invalid selection. Choose a listed number."
            continue
        fi

        if ! oh-my-posh print primary --config "$theme_dir/$theme.omp.json" >/dev/null 2>&1; then
            print -u2 "Theme failed validation: $theme"
            return 1
        fi

        print -r -- "$theme" > "$selection_file" || return 1
        print "Selected theme: $theme"
        print "Open a new terminal (or run 'exec zsh') to apply."
        return 0
    done
}
# <<< Oh My Posh theme selector <<<
