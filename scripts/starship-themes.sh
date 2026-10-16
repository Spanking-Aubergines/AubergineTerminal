#!/usr/bin/env bash
set -Eeuo pipefail

REPO_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
THEME_DIR="$REPO_DIR/zsh/.config/starship/themes"
SELECTION_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/starship-theme"

usage() {
    cat <<'USAGE'
Usage: starship-themes.sh COMMAND [THEME]

Commands:
  list             List available themes
  current          Show the saved theme
  preview THEME    Preview without changing the saved theme
  apply THEME      Save a theme for future Zsh sessions
  menu             Interactive theme selector
  help             Show this help
USAGE
}

fail() {
    printf 'Error: %s\n' "$*" >&2
    exit 1
}

validate_theme() {
    local theme="${1:-}"
    [[ "$theme" =~ ^[a-zA-Z0-9_-]+$ ]] ||
        fail "Invalid theme name: $theme"

    [[ -r "$THEME_DIR/$theme.toml" ]] ||
        fail "Theme not found: $theme"

    command -v starship >/dev/null 2>&1 ||
        fail "Starship is not installed"

    STARSHIP_CONFIG="$THEME_DIR/$theme.toml" \
        starship explain >/dev/null 2>&1 ||
        fail "Starship rejected theme: $theme"
}

list_themes() {
    local file
    local found=0

    printf 'Available Starship themes:\n'
    for file in "$THEME_DIR"/*.toml; do
        [[ -f "$file" ]] || continue
        printf '  %s\n' "${file##*/}"
        found=1
    done

    ((found)) || fail "No themes found in $THEME_DIR"
}

preview_theme() {
    local theme="$1"
    validate_theme "$theme"

    printf '\nPreview: %s\n' "$theme"
    printf '%s\n' '----------------------------------------'
    STARSHIP_CONFIG="$THEME_DIR/$theme.toml" starship prompt 2>&1 | command sed -e 's|%{||g' -e 's|%}||g'
    printf '\n%s\n\n' '----------------------------------------'
    printf 'Saved selection remains: '
    if [[ -r "$SELECTION_FILE" ]]; then
        cat -- "$SELECTION_FILE"
    else
        printf '%s\n' 'default (voight)'
    fi
}

apply_theme() {
    local theme="$1"
    local config_dir temp_file

    validate_theme "$theme"

    config_dir="${SELECTION_FILE%/*}"
    mkdir -p -- "$config_dir"
    temp_file="$(mktemp "$config_dir/.starship-theme.XXXXXX")"

    if ! printf '%s\n' "$theme" > "$temp_file"; then
        rm -f -- "$temp_file"
        fail "Could not write theme selection"
    fi

    if ! mv -f -- "$temp_file" "$SELECTION_FILE"; then
        rm -f -- "$temp_file"
        fail "Could not save theme selection"
    fi

    printf 'Saved Starship theme: %s\n' "$theme"
    printf 'New Zsh sessions will use this theme.\n'
    printf 'To activate it in your current shell, run: exec zsh\n'
}


theme_menu() {
    local file theme choice action answer current
    local -a themes=()

    while true; do
        themes=()
        for file in "$THEME_DIR"/*.toml; do
            [[ -f "$file" ]] || continue
            themes+=("${file##*/}")
        done

        if ((${#themes[@]} == 0)); then
            printf 'No Starship themes found.\n'
            return 1
        fi

        current="voight"
        if [[ -r "$SELECTION_FILE" ]]; then
            current="$(<"$SELECTION_FILE")"
        fi

        printf '\nSTARSHIP THEMES\n'
        printf '%s\n' '------------------------------'
        printf 'Saved theme: %s\n\n' "$current"

        for file in "${!themes[@]}"; do
            theme="${themes[$file]%.toml}"
            if [[ "$theme" == "$current" ]]; then
                printf '  %d) %s [current]\n' "$((file + 1))" "$theme"
            else
                printf '  %d) %s\n' "$((file + 1))" "$theme"
            fi
        done

        printf '\nChoose a theme number, or press Enter to return: '
        IFS= read -r choice || return 0
        [[ -z "$choice" ]] && return 0

        if [[ ! "$choice" =~ ^[0-9]+$ ]] ||
           ((choice < 1 || choice > ${#themes[@]})); then
            printf 'Invalid selection.\n'
            continue
        fi

        theme="${themes[$((choice - 1))]%.toml}"
        printf '\nSelected: %s\n' "$theme"
        printf '  1) Preview (no changes)\n'
        printf '  2) Apply as saved theme\n'
        printf '  3) Back\n'
        printf 'Action: '
        IFS= read -r action || return 0

        case "$action" in
            1)
                preview_theme "$theme"
                printf '\nPress Enter to continue...'
                IFS= read -r answer || true
                ;;
            2)
                printf 'Save "%s" for future Zsh sessions? [y/N] ' "$theme"
                IFS= read -r answer || return 0
                case "$answer" in
                    y|Y|yes|YES) apply_theme "$theme" ;;
                    *) printf 'Cancelled; saved theme remains %s.\n' "$current" ;;
                esac
                printf '\nPress Enter to continue...'
                IFS= read -r answer || true
                ;;
            3|"") ;;
            *) printf 'Invalid action.\n' ;;
        esac
    done
}

case "${1:-help}" in
    list)
        list_themes
        ;;
    menu)
        theme_menu
        ;;
    current)
        if [[ -r "$SELECTION_FILE" ]]; then
            printf 'Saved theme: '
            cat -- "$SELECTION_FILE"
        else
            printf 'Saved theme: voight (default)\n'
        fi
        ;;
    preview)
        [[ $# -eq 2 ]] || fail "Usage: $0 preview THEME"
        preview_theme "$2"
        ;;
    apply)
        [[ $# -eq 2 ]] || fail "Usage: $0 apply THEME"
        apply_theme "$2"
        ;;
    help|-h|--help)
        usage
        ;;
    *)
        usage >&2
        exit 2
        ;;
esac
