#!/usr/bin/env bash
set -Eeuo pipefail

REPO_URL="${DOTFILES_REPO_URL:-}"
TARGET_DIR="${DOTFILES_DIR:-$HOME/.dotfiles}"

usage() {
    cat <<USAGE
Usage: bootstrap.sh [-r REPO_URL] [-d TARGET_DIR] [-- INSTALLER_ARGS...]

Clone the dotfiles repository and run its installer.

Options:
  -r REPO_URL   Git URL to clone (or set DOTFILES_REPO_URL)
  -d TARGET_DIR Where to clone (default: \$HOME/.dotfiles, or \$DOTFILES_DIR)
  -h            Show this help

Any arguments after -- are passed to scripts/install.sh.
USAGE
}

INSTALLER_ARGS=()
while (($#)); do
    case "$1" in
        -r) REPO_URL="${2:-}"; shift 2 ;;
        -d) TARGET_DIR="${2:-}"; shift 2 ;;
        -h|--help) usage; exit 0 ;;
        --) shift; INSTALLER_ARGS=("$@"); break ;;
        *) printf 'Unknown argument: %s\n' "$1" >&2; usage >&2; exit 2 ;;
    esac
done

if [[ -z "$REPO_URL" ]]; then
    printf 'Error: repository URL required. Set DOTFILES_REPO_URL or pass -r.\n' >&2
    usage >&2
    exit 2
fi

if ! command -v git >/dev/null 2>&1; then
    printf 'Error: git is required to bootstrap.\n' >&2
    exit 1
fi

if [[ -e "$TARGET_DIR" ]]; then
    printf 'Error: target already exists: %s\n' "$TARGET_DIR" >&2
    printf 'Remove it or choose another location with -d.\n' >&2
    exit 1
fi

printf 'Cloning %s into %s\n' "$REPO_URL" "$TARGET_DIR"
git clone --depth=1 -- "$REPO_URL" "$TARGET_DIR"

printf '\nRunning installer...\n'
exec "$TARGET_DIR/scripts/install.sh" "${INSTALLER_ARGS[@]}"
