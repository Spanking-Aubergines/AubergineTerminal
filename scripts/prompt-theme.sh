#!/usr/bin/env bash
set -Eeuo pipefail

REPO_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
THEME_DIR="$REPO_DIR/zsh/.config/ohmyposh/themes"
SELECTION_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/ohmyposh-theme"

usage() {
    cat <<USAGE
Usage: prompt-theme.sh [THEME]

With no arguments, list available themes and prompt for a selection.
With THEME, validate and select it directly.

The active theme is stored in: $SELECTION_FILE
USAGE
}

require_omp() {
    if ! command -v oh-my-posh >/dev/null 2>&1; then
        printf 'Error: oh-my-posh is not installed.\n' >&2
        exit 1
    fi
}

list_themes() {
    local f
    for f in "$THEME_DIR"/*.omp.json; do
        [[ -f "$f" ]] || continue
        f="${f##*/}"
        printf '%s\n' "${f%.omp.json}"
    done
}

validate_theme() {
    local theme="$1"
    oh-my-posh print primary --config "$THEME_DIR/$theme.omp.json" >/dev/null 2>&1
}

save_theme() {
    local theme="$1"
    mkdir -p "$(dirname -- "$SELECTION_FILE")"
    printf '%s\n' "$theme" > "$SELECTION_FILE"
    printf 'Selected theme: %s\n' "$theme"
    printf 'Open a new terminal (or run "exec zsh") to apply.\n'
}

require_omp

if [[ ! -d "$THEME_DIR" ]]; then
    printf 'Error: theme directory not found: %s\n' "$THEME_DIR" >&2
    exit 1
fi

if (($# > 0)); then
    theme="$1"
    if [[ ! -r "$THEME_DIR/$theme.omp.json" ]]; then
        printf 'Error: unknown theme: %s\n' "$theme" >&2
        exit 1
    fi
    if ! validate_theme "$theme"; then
        printf 'Error: theme failed validation: %s\n' "$theme" >&2
        exit 1
    fi
    save_theme "$theme"
    exit 0
fi

mapfile -t themes < <(list_themes)
if ((${#themes[@]} == 0)); then
    printf 'No Oh My Posh themes found in %s\n' "$THEME_DIR" >&2
    exit 1
fi

printf 'Available Oh My Posh themes:\n'
for i in "${!themes[@]}"; do
    printf '  %2d) %s\n' "$((i + 1))" "${themes[$i]}"
done

printf '\nChoice (blank to cancel): '
read -r choice
[[ -z "$choice" ]] && { printf 'Cancelled.\n'; exit 0; }

if [[ ! "$choice" =~ ^[0-9]+$ ]] || ((choice < 1 || choice > ${#themes[@]})); then
    printf 'Error: invalid selection.\n' >&2
    exit 1
fi

theme="${themes[$((choice - 1))]}"
if ! validate_theme "$theme"; then
    printf 'Error: theme failed validation: %s\n' "$theme" >&2
    exit 1
fi
save_theme "$theme"
