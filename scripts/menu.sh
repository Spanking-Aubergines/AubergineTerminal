#!/usr/bin/env bash
set -Eeuo pipefail

REPO_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
INSTALL="$REPO_DIR/scripts/install.sh"
UNSTOW="$REPO_DIR/scripts/unstow.sh"
HOOKS="$REPO_DIR/scripts/install-hooks.sh"
TESTS="$REPO_DIR/tests/run-all.sh"

if [[ ! -x "$INSTALL" ]]; then
    printf 'Error: installer not found: %s\n' "$INSTALL" >&2
    exit 1
fi

pause() {
    printf '\nPress Enter to return to the menu...'
    read -r _
}

run_action() {
    printf '\n'
    "$@" || printf '\n(exit status: %s)\n' "$?"
    pause
}

discover_stow_packages() {
    local entry base
    for entry in "$REPO_DIR"/*/; do
        [[ -d "$entry" ]] || continue
        base="$(basename -- "$entry")"
        case "$base" in
            docs|packages|scripts|tests) continue ;;
        esac
        if [[ -n "$(command find "$entry" -maxdepth 1 -name '.*' -print -quit 2>/dev/null)" ]]; then
            printf '%s\n' "$base"
        fi
    done
}

pick_package() {
    local -a pkgs=()
    while IFS= read -r p; do
        [[ -n "$p" ]] && pkgs+=("$p")
    done < <(discover_stow_packages)

    if ((${#pkgs[@]} == 0)); then
        printf 'No Stow packages found.\n' >&2
        return 1
    fi

    printf '\nAvailable packages:\n' >&2
    local i=1
    for p in "${pkgs[@]}"; do
        printf '  %2d) %s\n' "$i" "$p" >&2
        i=$((i + 1))
    done
    printf '\n' >&2

    local choice
    read -r -p 'Package number (blank to cancel): ' choice
    [[ -z "$choice" ]] && return 1

    if [[ ! "$choice" =~ ^[0-9]+$ ]] || ((choice < 1 || choice > ${#pkgs[@]})); then
        printf 'Invalid selection.\n' >&2
        return 1
    fi

    printf '%s\n' "${pkgs[$((choice - 1))]}"
}

while true; do
    printf '\n=== dotfiles menu ===\n'
    printf '  1) Show package status (dry-run)\n'
    printf '  2) Install missing packages\n'
    printf '  3) Preview Stow deployment (all packages)\n'
    printf '  4) Deploy all Stow packages\n'
    printf '  5) Deploy one Stow package\n'
    printf '  6) Unstow one package (dry-run)\n'
    printf '  7) Unstow one package (apply)\n'
    printf '  8) Set login shell to Zsh\n'
    printf '  9) Install Git hooks\n'
    printf ' 10) Run all tests\n'
    printf ' 11) Show installer help\n'
    printf '  0) Quit\n'
    printf '\nChoice: '
    read -r choice || exit 0

    case "$choice" in
        1) run_action "$INSTALL" ;;
        2) run_action "$INSTALL" --install ;;
        3) run_action "$INSTALL" --stow all ;;
        4) run_action "$INSTALL" --stow all --apply ;;
        5)
            if pkg="$(pick_package)"; then
                run_action "$INSTALL" --stow "$pkg"
            else
                pause
            fi
            ;;
        6)
            if pkg="$(pick_package)"; then
                run_action "$UNSTOW" "$pkg"
            else
                pause
            fi
            ;;
        7)
            if pkg="$(pick_package)"; then
                run_action "$UNSTOW" "$pkg" --apply
            else
                pause
            fi
            ;;
        8) run_action "$INSTALL" --set-shell ;;
        9) run_action "$HOOKS" ;;
        10) run_action "$TESTS" ;;
        11) run_action "$INSTALL" --help ;;
        0|q|Q) printf 'Bye.\n'; exit 0 ;;
        *) printf 'Unknown choice: %s\n' "$choice" ;;
    esac
done
