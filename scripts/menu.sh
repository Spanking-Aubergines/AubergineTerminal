#!/usr/bin/env bash
set -Eeuo pipefail

REPO_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
INSTALL="$REPO_DIR/scripts/install.sh"
UNSTOW="$REPO_DIR/scripts/unstow.sh"
HOOKS="$REPO_DIR/scripts/install-hooks.sh"
TESTS="$REPO_DIR/tests/run-all.sh"

# Enable colour only for a suitable interactive terminal.
if [[ -t 1 && "${TERM:-dumb}" != dumb && -z "${NO_COLOR:-}" ]]; then
    C_RESET=$'\033[0m'
    C_BOLD=$'\033[1m'
    C_DIM=$'\033[2m'
    C_PURPLE=$'\033[38;5;141m'
    C_CYAN=$'\033[38;5;81m'
    C_GREEN=$'\033[38;5;114m'
    C_YELLOW=$'\033[38;5;221m'
    C_RED=$'\033[38;5;203m'
else
    C_RESET=''
    C_BOLD=''
    C_DIM=''
    C_PURPLE=''
    C_CYAN=''
    C_GREEN=''
    C_YELLOW=''
    C_RED=''
fi

if [[ ! -x "$INSTALL" ]]; then
    printf 'Error: installer not found or not executable: %s\n' "$INSTALL" >&2
    exit 1
fi

print_header() {
    local os_name branch repo_state

    os_name="Unknown Linux"
    if [[ -r /etc/os-release ]]; then
        # shellcheck disable=SC1091
        . /etc/os-release
        os_name="${PRETTY_NAME:-${NAME:-Unknown Linux}}"
    fi

    branch="$(git -C "$REPO_DIR" branch --show-current 2>/dev/null || printf 'unknown')"

    if git -C "$REPO_DIR" diff --quiet --ignore-submodules -- 2>/dev/null &&
       git -C "$REPO_DIR" diff --cached --quiet --ignore-submodules -- 2>/dev/null; then
        repo_state="working tree clean"
    else
        repo_state="uncommitted changes"
    fi

    printf '\n'
    printf '%s╭──────────────────────────────────────────────────────────────╮%s\n' "$C_PURPLE" "$C_RESET"
    printf '%s│%s  %sAUBERGINE TERMINAL%s                                      %s│%s\n' \
        "$C_PURPLE" "$C_RESET" "$C_BOLD" "$C_RESET" "$C_PURPLE" "$C_RESET"
    printf '%s│%s  %sdotfiles manager%s                                          %s│%s\n' \
        "$C_PURPLE" "$C_RESET" "$C_DIM" "$C_RESET" "$C_PURPLE" "$C_RESET"
    printf '%s╰──────────────────────────────────────────────────────────────╯%s\n' "$C_PURPLE" "$C_RESET"
    printf '  %sOS%s       %s\n' "$C_CYAN" "$C_RESET" "$os_name"
    printf '  %sRepo%s     %s\n' "$C_CYAN" "$C_RESET" "$REPO_DIR"
    printf '  %sBranch%s   %s  %s(%s)%s\n' \
        "$C_CYAN" "$C_RESET" "$branch" "$C_DIM" "$repo_state" "$C_RESET"
}

status_item() {
    local label="$1" state="$2" detail="${3:-}"

    case "$state" in
        ok)      printf '  %s[ OK ]%s  %-15s %s\n' "$C_GREEN" "$C_RESET" "$label" "$detail" ;;
        warn)    printf '  %s[WARN]%s  %-15s %s\n' "$C_YELLOW" "$C_RESET" "$label" "$detail" ;;
        missing) printf '  %s[MISS]%s  %-15s %s\n' "$C_RED" "$C_RESET" "$label" "$detail" ;;
        info)    printf '  %s[INFO]%s  %-15s %s\n' "$C_CYAN" "$C_RESET" "$label" "$detail" ;;
    esac
}

show_system_status() {
    local os_id="unknown"
    local os_name="Unknown Linux"
    local package_manager="unsupported"
    local manifest=""
    local branch="" remote_count=0
    local staged=0 unstaged=0 untracked=0
    local package_count=0 pkg

    if [[ -r /etc/os-release ]]; then
        # shellcheck disable=SC1091
        . /etc/os-release
        os_id="${ID:-unknown}"
        os_name="${PRETTY_NAME:-${NAME:-Unknown Linux}}"
    fi

    case "$os_id" in
        arch)
            package_manager="pacman"
            manifest="$REPO_DIR/packages/arch/required.txt"
            ;;
        debian)
            package_manager="apt-get"
            manifest="$REPO_DIR/packages/debian/required.txt"
            ;;
    esac

    printf '\n%sSYSTEM DASHBOARD%s\n' "$C_BOLD" "$C_RESET"
    printf '%s──────────────────────────────────────────────────────────────%s\n' "$C_DIM" "$C_RESET"

    printf '  %s%-12s%s %s\n' "$C_CYAN" "Operating OS" "$C_RESET" "$os_name"

    if [[ "$package_manager" == unsupported ]]; then
        status_item "Package mgr" warn "unsupported distribution: $os_id"
    elif command -v "$package_manager" >/dev/null 2>&1; then
        status_item "Package mgr" ok "$package_manager"
    else
        status_item "Package mgr" missing "$package_manager not found"
    fi

    if [[ "$package_manager" != unsupported ]]; then
        if [[ -r "$manifest" ]]; then
            status_item "Manifest" ok "${manifest#"$REPO_DIR"/}"
        else
            status_item "Manifest" missing "${manifest#"$REPO_DIR"/} not readable"
        fi
    else
        status_item "Manifest" warn "no manifest for this distribution"
    fi

    if command -v git >/dev/null 2>&1; then
        status_item "Git" ok "$(git --version)"
    else
        status_item "Git" missing "not found"
    fi

    if command -v stow >/dev/null 2>&1; then
        status_item "GNU Stow" ok "$(stow --version 2>/dev/null | command head -n 1)"
    else
        status_item "GNU Stow" warn "not found; deployment unavailable"
    fi

    if command -v zsh >/dev/null 2>&1; then
        status_item "Zsh" ok "$(zsh --version 2>/dev/null)"
    else
        status_item "Zsh" warn "optional; not installed"
    fi

    for pkg in "$INSTALL" "$UNSTOW"; do
        if [[ -x "$pkg" ]]; then
            status_item "$(basename -- "$pkg")" ok "executable"
        else
            status_item "$(basename -- "$pkg")" missing "missing or not executable"
        fi
    done

    if [[ -x "$HOOKS" ]]; then
        status_item "Git hooks" ok "installer available"
    else
        status_item "Git hooks" warn "installer missing or not executable"
    fi

    if [[ -x "$TESTS" ]]; then
        status_item "Test runner" ok "available"
    else
        status_item "Test runner" warn "missing or not executable"
    fi

    if command -v git >/dev/null 2>&1 &&
       git -C "$REPO_DIR" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        branch="$(git -C "$REPO_DIR" branch --show-current 2>/dev/null || true)"
        [[ -n "$branch" ]] || branch="detached HEAD"
        status_item "Git branch" info "$branch"

        remote_count="$(git -C "$REPO_DIR" remote 2>/dev/null | command wc -l)"
        if ((remote_count > 0)); then
            status_item "Git remote" ok "$remote_count configured"
        else
            status_item "Git remote" warn "no remote configured"
        fi

        git -C "$REPO_DIR" diff --cached --quiet --ignore-submodules -- ||
            staged=1
        git -C "$REPO_DIR" diff --quiet --ignore-submodules -- ||
            unstaged=1

        if ((staged)); then
            status_item "Staged" warn "changes staged for commit"
        else
            status_item "Staged" ok "none"
        fi

        if ((unstaged)); then
            status_item "Unstaged" warn "tracked files modified"
        else
            status_item "Unstaged" ok "none"
        fi

        if [[ -n "$(git -C "$REPO_DIR" ls-files --others --exclude-standard 2>/dev/null)" ]]; then
            untracked=1
        fi

        if ((untracked)); then
            status_item "Untracked" warn "untracked files present"
        else
            status_item "Untracked" ok "none"
        fi

        if git -C "$REPO_DIR" rev-parse --abbrev-ref '@{upstream}' >/dev/null 2>&1; then
            status_item "Upstream" ok "tracking configured"
        else
            status_item "Upstream" info "no upstream for current branch"
        fi
    else
        status_item "Git repository" missing "repository metadata unavailable"
    fi

    while IFS= read -r pkg; do
        [[ -n "$pkg" ]] && package_count=$((package_count + 1))
    done < <(discover_stow_packages)

    status_item "Stow packages" info "$package_count discovered"

    printf '\n%sDiagnostics are read-only; no packages or configurations were changed.%s\n' \
        "$C_DIM" "$C_RESET"
}

pause() {
    printf '\n%sPress Enter to return to the menu...%s' "$C_DIM" "$C_RESET"
    read -r _ || true
}

run_action() {
    local result=0

    printf '\n%s▶ Running:%s' "$C_CYAN" "$C_RESET"
    printf ' %q' "$@"
    printf '\n\n'

    "$@" || result=$?

    if ((result == 0)); then
        printf '\n%s✓ Action completed successfully.%s\n' "$C_GREEN" "$C_RESET"
    else
        printf '\n%s! Action exited with status %s.%s\n' "$C_YELLOW" "$result" "$C_RESET"
    fi

    pause
    return 0
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
    local p choice i

    while IFS= read -r p; do
        [[ -n "$p" ]] && pkgs+=("$p")
    done < <(discover_stow_packages)

    if ((${#pkgs[@]} == 0)); then
        printf 'No Stow packages found.\n' >&2
        return 1
    fi

    printf '\n%sAVAILABLE STOW PACKAGES%s\n' "$C_BOLD" "$C_RESET" >&2
    i=1
    for p in "${pkgs[@]}"; do
        printf '  %s%2d)%s %s\n' "$C_CYAN" "$i" "$C_RESET" "$p" >&2
        i=$((i + 1))
    done
    printf '\n' >&2

    read -r -p 'Package number (blank to cancel): ' choice
    [[ -z "$choice" ]] && return 1

    if [[ ! "$choice" =~ ^[0-9]+$ ]] || ((choice < 1 || choice > ${#pkgs[@]})); then
        printf 'Invalid selection.\n' >&2
        return 1
    fi

    printf '%s\n' "${pkgs[$((choice - 1))]}"
}

full_setup() {
    local answer

    printf '\n%sFULL SETUP%s\n\n' "$C_BOLD" "$C_RESET"
    printf 'This will:\n'
    printf '  1. Check required packages and ask before installing missing ones\n'
    printf '  2. Deploy every Stow package, asking before creating symlinks\n'
    printf '  3. Offer to change the login shell to Zsh\n\n'

    read -r -p 'Continue? [y/N] ' answer
    case "$answer" in
        y|Y|yes|YES) ;;
        *) printf 'Cancelled.\n'; return 0 ;;
    esac

    printf '\n%s── Step 1/3: packages ──%s\n' "$C_PURPLE" "$C_RESET"
    "$INSTALL" --install || true

    printf '\n%s── Step 2/3: Stow packages ──%s\n' "$C_PURPLE" "$C_RESET"
    "$INSTALL" --stow all --apply || true

    printf '\n%s── Step 3/3: login shell ──%s\n' "$C_PURPLE" "$C_RESET"
    read -r -p 'Change login shell to Zsh now? [y/N] ' answer
    case "$answer" in
        y|Y|yes|YES) "$INSTALL" --set-shell || true ;;
        *) printf 'Leaving login shell unchanged.\n' ;;
    esac

    pause
}

show_menu() {
    local selected="${1:-0}"
    local i label number
    local -a labels=(
        "Full setup                 Packages + Stow + shell"
        "Show package status        Dry-run"
        "Install missing packages"
        "Preview Stow deployment    All packages"
        "Deploy all Stow packages"
        "Deploy one Stow package"
        "Unstow one package         Dry-run"
        "Unstow one package         Apply"
        "Set login shell to Zsh"
        "Install Git hooks"
        "Run all tests"
        "Show installer help"
        "Oh My Posh Themes          Preview and apply themes"
    )

    printf '\n%sACTIONS%s  %s↑/↓ navigate · Enter select · number + Enter shortcut%s\n' \
        "$C_BOLD" "$C_RESET" "$C_DIM" "$C_RESET"

    printf '%s──────────────────────────────────────────────────────────────%s\n' "$C_DIM" "$C_RESET"

    for i in "${!labels[@]}"; do
        number=$((i + 1))
        if ((i == selected)); then
            printf '  %s%s%2d  %-44s%s\n' \
                "$C_PURPLE" "$C_BOLD" "$number" "${labels[$i]}" "$C_RESET"
        else
            printf '  %s%2d%s  %s\n' "$C_CYAN" "$number" "$C_RESET" "${labels[$i]}"
        fi
    done

    printf '%s──────────────────────────────────────────────────────────────%s\n' "$C_DIM" "$C_RESET"
    printf '  %sS%s  Refresh dashboard    %sQ%s  Quit\n' "$C_GREEN" "$C_RESET" "$C_RED" "$C_RESET"
}

read_menu_choice() {
    local selected=0 key sequence digits="" saved_tty

    # Keep piped/scripted use predictable and compatible with regression tests.
    if [[ ! -t 0 || ! -t 1 ]]; then
        print_header
        show_system_status
        show_menu
        printf '\nChoice (number, S to refresh, Q to quit): '
        IFS= read -r choice || return 1
        return 0
    fi

    saved_tty="$(stty -g)" || return 1
    if ! stty -echo -icanon min 1 time 0; then
        return 1
    fi

    redraw_menu() {
        printf '\033[2J\033[H'
        print_header
        show_system_status
        show_menu "$selected"
        printf '\n%sSelect%s ' "$C_BOLD" "$C_RESET"
        if [[ -n "$digits" ]]; then
            printf '%s%s%s' "$C_CYAN" "$digits" "$C_RESET"
        else
            printf '%sUse arrows and Enter%s' "$C_DIM" "$C_RESET"
        fi
        printf '  '
    }

    restore_menu_tty() {
        stty "$saved_tty" 2>/dev/null || true
    }

    redraw_menu

    while IFS= read -r -s -N 1 key; do
        case "$key" in
            $'\x1b')
                sequence=""
                IFS= read -r -s -n 2 -t 1 sequence || true
                case "$sequence" in
                    '[A')
                        selected=$(((selected + 12) % 13))
                        digits=""
                        redraw_menu
                        ;;
                    '[B')
                        selected=$(((selected + 1) % 13))
                        digits=""
                        redraw_menu
                        ;;
                esac
                ;;
            $'\r'|$'\n')
                restore_menu_tty
                if [[ -n "$digits" ]]; then
                    choice="$digits"
                else
                    choice="$((selected + 1))"
                fi
                printf '\n'
                return 0
                ;;
            [0-9])
                digits+="$key"
                redraw_menu
                ;;
            $'\177'|$'\b')
                digits="${digits%?}"
                redraw_menu
                ;;
            s|S|q|Q)
                restore_menu_tty
                choice="$key"
                printf '\n'
                return 0
                ;;
            *)
                ;;
        esac
    done

    restore_menu_tty
    return 1
}

while true; do
    read_menu_choice || exit 0

    case "$choice" in
        1|01) full_setup ;;
        2|02) run_action "$INSTALL" ;;
        3|03) run_action "$INSTALL" --install ;;
        4|04) run_action "$INSTALL" --stow all ;;
        5|05) run_action "$INSTALL" --stow all --apply ;;
        6|06)
            if pkg="$(pick_package)"; then
                run_action "$INSTALL" --stow "$pkg"
            else
                printf 'Package selection cancelled or invalid.\n'
                pause
            fi
            ;;
        7|07)
            if pkg="$(pick_package)"; then
                run_action "$UNSTOW" "$pkg"
            else
                printf 'Package selection cancelled or invalid.\n'
                pause
            fi
            ;;
        8|08)
            if pkg="$(pick_package)"; then
                run_action "$UNSTOW" "$pkg" --apply
            else
                printf 'Package selection cancelled or invalid.\n'
                pause
            fi
            ;;
        9|09) run_action "$INSTALL" --set-shell ;;
        10) run_action "$HOOKS" ;;
        11) run_action "$TESTS" ;;
        12) run_action "$INSTALL" --help ;;
        13) run_action "$REPO_DIR/scripts/prompt-theme.sh" ;;
        s|S) continue ;;
        0|q|Q) printf '\nBye.\n'; exit 0 ;;
        *) printf '\n%sUnknown choice:%s %s\n' "$C_YELLOW" "$C_RESET" "$choice"; pause ;;
    esac
done
