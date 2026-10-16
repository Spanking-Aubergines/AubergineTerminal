#!/usr/bin/env bash
set -Eeuo pipefail

# Dotfiles bootstrap and configuration deployment.
# Package installation and Stow deployment are separate operations.

MODE="dry-run"
STOW_PACKAGE=""

usage() {
    cat <<USAGE
Usage:
  $0 [--dry-run | --install]
  $0 --stow PACKAGE [--apply]
  $0 --set-shell
  $0 --help

Options:
  --dry-run       Preview missing required packages (default)
  --install       Ask before installing missing required packages
  --stow PACKAGE  Preview deployment of a Stow package
  --apply         Apply the selected Stow package (requires --stow)
  --set-shell     Offer to change the login shell to Zsh
  --help, -h      Show this help

Examples:
  $0
  $0 --install
  $0 --stow zsh
  $0 --stow zsh --apply
USAGE
}

APPLY_STOW=false
SET_SHELL=false
MODE_EXPLICIT=false
STOW_EXPLICIT=false

while (($#)); do
    case "$1" in
        --dry-run|--install)
            if [[ "$MODE_EXPLICIT" == true ]]; then
                printf 'Error: specify only one of --dry-run or --install.\n' >&2
                exit 2
            fi
            MODE_EXPLICIT=true
            if [[ "$1" == "--install" ]]; then
                MODE="install"
            else
                MODE="dry-run"
            fi
            ;;
        --stow)
            if [[ "$STOW_EXPLICIT" == true ]]; then
                printf 'Error: --stow may be specified only once.\n' >&2
                exit 2
            fi
            if (($# < 2)) || [[ -z "${2:-}" || "$2" == --* ]]; then
                printf 'Error: --stow requires a package name.\n' >&2
                usage >&2
                exit 2
            fi
            STOW_EXPLICIT=true
            STOW_PACKAGE="$2"
            shift
            ;;
        --apply)
            if [[ "$APPLY_STOW" == true ]]; then
                printf 'Error: --apply may be specified only once.\n' >&2
                exit 2
            fi
            APPLY_STOW=true
            ;;
        --set-shell)
            if [[ "$SET_SHELL" == true ]]; then
                printf 'Error: --set-shell may be specified only once.\n' >&2
                exit 2
            fi
            SET_SHELL=true
            ;;
        --help|-h)
            usage
            exit 0
            ;;
        *)
            printf 'Error: unknown option: %s\n' "$1" >&2
            usage >&2
            exit 2
            ;;
    esac
    shift
done

if [[ "$SET_SHELL" == true ]] &&
   { [[ "$MODE_EXPLICIT" == true ]] || [[ "$STOW_EXPLICIT" == true ]] || [[ "$APPLY_STOW" == true ]]; }; then
    printf 'Error: --set-shell cannot be combined with other actions.\n' >&2
    exit 2
fi

if [[ "$STOW_EXPLICIT" == true && "$MODE" == "install" ]]; then
    printf 'Error: --install cannot be combined with --stow.\n' >&2
    exit 2
fi

if [[ "$APPLY_STOW" == true && "$STOW_EXPLICIT" == false ]]; then
    printf 'Error: --apply requires --stow PACKAGE.\n' >&2
    exit 2
fi

if [[ -z "${BASH_VERSION:-}" ]]; then
    printf 'Error: this installer must run under Bash.\n' >&2
    exit 1
fi

REPO_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"

if [[ "$SET_SHELL" == true ]]; then
    if [[ "$MODE" != "dry-run" || -n "$STOW_PACKAGE" || "$APPLY_STOW" == true ]]; then
        printf 'Error: --set-shell cannot be combined with other actions.\n' >&2
        exit 2
    fi

    if ! command -v zsh >/dev/null 2>&1; then
        printf 'Error: Zsh is not installed. Run the package installer first.\n' >&2
        exit 1
    fi

    SHELL_PATH="/usr/bin/zsh"

    if [[ ! -x "$SHELL_PATH" ]] || ! grep -Fxq "$SHELL_PATH" /etc/shells; then
        printf 'Error: %s is not an executable permitted login shell.\n' "$SHELL_PATH" >&2
        printf 'No changes made.\n' >&2
        exit 1
    fi

    CURRENT_SHELL="$(getent passwd "$USER" | cut -d: -f7)"
    printf 'User:          %s\n' "$USER"
    printf 'Current shell: %s\n' "$CURRENT_SHELL"
    printf 'New shell:     %s\n' "$SHELL_PATH"

    if [[ "$CURRENT_SHELL" == "$SHELL_PATH" ]]; then
        printf '\nZsh is already your login shell.\n'
        exit 0
    fi

    printf '\nThis changes your login shell. Existing sessions will not change.\n'
    read -r -p 'Continue? [y/N] ' answer
    case "$answer" in
        y|Y|yes|YES) ;;
        *)
            printf 'Cancelled; login shell unchanged.\n'
            exit 0
            ;;
    esac

    if ! command -v chsh >/dev/null 2>&1; then
        printf 'Error: chsh is not available.\n' >&2
        exit 1
    fi

    chsh -s "$SHELL_PATH" "$USER"
    printf '\nShell-change command completed. Verify with:\n'
    printf "  getent passwd \"\$USER\" | cut -d: -f1,7\n"
    exit 0
fi

# Discover Stow packages: top-level dirs containing at least one dot-entry.
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

# Stow deployment mode.
if [[ -n "$STOW_PACKAGE" ]]; then
    if [[ "$MODE" != "dry-run" ]]; then
        printf 'Error: package installation options cannot be combined with --stow.\n' >&2
        exit 2
    fi

    if ! command -v stow >/dev/null 2>&1; then
        printf 'Error: GNU Stow is not installed. Run the package installer first.\n' >&2
        exit 1
    fi

    declare -a stow_packages=()
    if [[ "$STOW_PACKAGE" == "all" ]]; then
        while IFS= read -r pkg; do
            [[ -n "$pkg" ]] && stow_packages+=("$pkg")
        done < <(discover_stow_packages)
        if ((${#stow_packages[@]} == 0)); then
            printf 'Error: no Stow packages found in %s\n' "$REPO_DIR" >&2
            exit 1
        fi
    else
        if [[ ! "$STOW_PACKAGE" =~ ^[a-zA-Z0-9_-]+$ ]]; then
            printf 'Error: invalid Stow package name: %s\n' "$STOW_PACKAGE" >&2
            exit 2
        fi
        PACKAGE_DIR="$REPO_DIR/$STOW_PACKAGE"
        if [[ ! -d "$PACKAGE_DIR" ]]; then
            printf 'Error: Stow package directory not found: %s\n' "$PACKAGE_DIR" >&2
            exit 1
        fi
        stow_packages=("$STOW_PACKAGE")
    fi

    printf 'Repository:    %s\n' "$REPO_DIR"
    printf 'Stow packages: %s\n' "${stow_packages[*]}"
    if [[ "$APPLY_STOW" == true ]]; then
        printf 'Mode:          apply\n\n'
    else
        printf 'Mode:          dry-run\n\n'
    fi

    if [[ "$APPLY_STOW" == true ]]; then
        printf 'This will create configuration symlinks in your home directory.\n'
        read -r -p 'Continue? [y/N] ' answer
        case "$answer" in
            y|Y|yes|YES) ;;
            *)
                printf 'Cancelled; no configuration changes made.\n'
                exit 0
                ;;
        esac
    fi

    for pkg in "${stow_packages[@]}"; do
        PACKAGE_DIR="$REPO_DIR/$pkg"

        printf '\n=== %s ===\n' "$pkg"

        if [[ "$pkg" == "zsh" ]]; then
            TARGET="$HOME/.zshrc"
            EXPECTED_TARGET="$PACKAGE_DIR/.zshrc"
            if [[ -e "$TARGET" || -L "$TARGET" ]]; then
                if [[ -L "$TARGET" && "$(readlink -f -- "$TARGET" 2>/dev/null || true)" == "$(readlink -f -- "$EXPECTED_TARGET")" ]]; then
                    printf 'The target %s is already managed by this package.\n' "$TARGET"
                else
                    printf 'Error: target exists and is not the expected Stow symlink: %s\n' "$TARGET" >&2
                    printf 'No changes made. Inspect or back up the target manually before retrying.\n' >&2
                    exit 1
                fi
            fi
        fi

        if [[ "$APPLY_STOW" == true ]]; then
            stow --no-folding --verbose --dir="$REPO_DIR" --target="$HOME" "$pkg"
        else
            stow --no-folding --no --verbose --dir="$REPO_DIR" --target="$HOME" "$pkg"
        fi
    done

    if [[ "$APPLY_STOW" == true ]]; then
        printf '\nStow deployment completed.\n'
    else
        printf '\nDry run only; no configuration changes were made.\n'
        printf 'Review the proposed links, then add --apply to deploy.\n'
    fi

    exit 0
fi

if [[ "$APPLY_STOW" == true ]]; then
    printf 'Error: --apply requires --stow PACKAGE.\n' >&2
    exit 2
fi

OS_RELEASE_FILE="${DOTFILES_OS_RELEASE_FILE:-/etc/os-release}"

if [[ ! -r "$OS_RELEASE_FILE" ]]; then
    printf 'Error: cannot identify this operating system.\n' >&2
    exit 1
fi

# shellcheck disable=SC1090,SC1091
source "$OS_RELEASE_FILE"

case "${ID:-}" in
    arch)
        MANIFEST="$REPO_DIR/packages/arch/required.txt"
        PACKAGE_MANAGER="pacman"
        ;;
    debian)
        MANIFEST="$REPO_DIR/packages/debian/required.txt"
        PACKAGE_MANAGER="apt-get"
        ;;
    *)
        printf 'Error: unsupported distribution: %s\n' "${ID:-unknown}" >&2
        printf 'Supported distributions: Arch Linux and Debian.\n' >&2
        exit 1
        ;;
esac

if [[ ! -r "$MANIFEST" ]]; then
    printf 'Error: package manifest not found: %s\n' "$MANIFEST" >&2
    exit 1
fi

if ! command -v "$PACKAGE_MANAGER" >/dev/null 2>&1; then
    printf 'Error: required package manager not found: %s\n' "$PACKAGE_MANAGER" >&2
    exit 1
fi

declare -a requested=()
declare -a missing=()

while IFS= read -r line || [[ -n "$line" ]]; do
    line="${line%%#*}"
    # Trim surrounding whitespace without altering package names.
    line="${line#"${line%%[![:space:]]*}"}"
    line="${line%"${line##*[![:space:]]}"}"
    [[ -z "$line" ]] && continue

    if [[ ! "$line" =~ ^[a-zA-Z0-9.+:-]+$ ]]; then
        printf 'Error: invalid package entry in %s: %s\n' "$MANIFEST" "$line" >&2
        exit 1
    fi

    for existing in "${requested[@]}"; do
        if [[ "$existing" == "$line" ]]; then
            printf 'Error: duplicate package entry in %s: %s\\n' "$MANIFEST" "$line" >&2
            exit 1
        fi
    done

    requested+=("$line")
done < "$MANIFEST"

if ((${#requested[@]} == 0)); then
    printf 'Error: no packages found in %s\n' "$MANIFEST" >&2
    exit 1
fi

is_installed() {
    local package="$1"

    case "$PACKAGE_MANAGER" in
        pacman)
            pacman -Q "$package" >/dev/null 2>&1
            ;;
        apt-get)
            dpkg-query -W -f='${Status}' "$package" 2>/dev/null |
                grep -qx 'install ok installed'
            ;;
    esac
}

printf 'Distribution: %s\n' "${PRETTY_NAME:-$ID}"
printf 'Manifest:     %s\n' "${MANIFEST#"$REPO_DIR"/}"
printf 'Mode:         %s\n\n' "$MODE"
printf '%s\n' 'Checking declared packages...'

for package in "${requested[@]}"; do
    if is_installed "$package"; then
        printf '  [installed] %s\n' "$package"
    else
        printf '  [missing]   %s\n' "$package"
        missing+=("$package")
    fi
done

if ((${#missing[@]} == 0)); then
    printf '\nAll required project packages are installed.\n'
    exit 0
fi

printf '\nPackages to install: %s\n' "${missing[*]}"

if [[ "$MODE" == "dry-run" ]]; then
    printf 'Dry run only; no system changes were made.\n'
    printf 'Review the list, then run with --install to proceed.\n'
    exit 0
fi

printf '\nThis will install the missing packages listed above.\n'
printf 'No packages will be removed.\n'
read -r -p 'Continue? [y/N] ' answer

case "$answer" in
    y|Y|yes|YES) ;;
    *)
        printf 'Cancelled; no packages were installed.\n'
        exit 0
        ;;
esac

if [[ "$EUID" -eq 0 ]]; then
    PRIVILEGE=()
elif command -v sudo >/dev/null 2>&1; then
    PRIVILEGE=(sudo)
else
    printf 'Error: install mode requires root or sudo privileges.\n' >&2
    exit 1
fi

case "$PACKAGE_MANAGER" in
    pacman)
        "${PRIVILEGE[@]}" pacman -S --needed "${missing[@]}"
        ;;
    apt-get)
        "${PRIVILEGE[@]}" apt-get update
        "${PRIVILEGE[@]}" apt-get install --no-install-recommends "${missing[@]}"
        ;;
esac

printf '\nPackage installation command completed.\n'
