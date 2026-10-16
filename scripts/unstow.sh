#!/usr/bin/env bash
set -Eeuo pipefail

REPO_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TARGET="${HOME}"
APPLY=false
PACKAGE=""

usage() {
    cat <<USAGE
Usage: unstow.sh PACKAGE [--apply]

Remove symlinks previously created by \`install.sh --stow PACKAGE\`.

By default this is a dry-run and prints the links that would be removed.

Options:
  --apply   Actually remove the symlinks.
  -h        Show this help.
USAGE
}

while (($#)); do
    case "$1" in
        --apply) APPLY=true; shift ;;
        -h|--help) usage; exit 0 ;;
        -*) printf 'Unknown option: %s\n' "$1" >&2; usage >&2; exit 2 ;;
        *)
            if [[ -n "$PACKAGE" ]]; then
                printf 'Error: only one package may be specified.\n' >&2
                exit 2
            fi
            PACKAGE="$1"
            shift
            ;;
    esac
done

if [[ -z "$PACKAGE" ]]; then
    printf 'Error: package name required.\n' >&2
    usage >&2
    exit 2
fi

if [[ ! "$PACKAGE" =~ ^[a-zA-Z0-9._-]+$ ]]; then
    printf 'Error: invalid package name: %s\n' "$PACKAGE" >&2
    exit 2
fi

PACKAGE_DIR="$REPO_DIR/$PACKAGE"
if [[ ! -d "$PACKAGE_DIR" ]]; then
    printf 'Error: package directory not found: %s\n' "$PACKAGE_DIR" >&2
    exit 1
fi

printf 'Package: %s\n' "$PACKAGE"
printf 'Target:  %s\n' "$TARGET"
if [[ "$APPLY" == true ]]; then
    printf 'Mode:    apply\n\n'
else
    printf 'Mode:    dry-run\n\n'
fi

removed=0
skipped=0

seen_dirs=""

while IFS= read -r -d '' file; do
    rel="${file#"$PACKAGE_DIR"/}"
    link="$TARGET/$rel"

    # If an ancestor directory is a symlink into this package, the whole
    # subtree is folded; handle the ancestor instead of the file.
    ancestor="$link"
    folded=""
    while [[ "$ancestor" != "$TARGET" && "$ancestor" != "/" ]]; do
        ancestor="$(dirname -- "$ancestor")"
        if [[ -L "$ancestor" ]] && \
           [[ "$(readlink -f -- "$ancestor" 2>/dev/null || true)" == "$PACKAGE_DIR"* ]]; then
            folded="$ancestor"
            break
        fi
    done
    if [[ -n "$folded" ]]; then
        case " $seen_dirs " in
            *" $folded "*) continue ;;
        esac
        seen_dirs="$seen_dirs $folded"
        if [[ "$APPLY" == true ]]; then
            rm -- "$folded"
            printf '  [removed] %s (folded directory)\n' "$folded"
        else
            printf '  [would remove] %s (folded directory)\n' "$folded"
        fi
        removed=$((removed + 1))
        continue
    fi

    if [[ ! -L "$link" ]]; then
        if [[ -e "$link" ]]; then
            printf '  [skip]    %s (not a symlink)\n' "$link"
            skipped=$((skipped + 1))
        fi
        continue
    fi

    actual="$(readlink -f -- "$link" 2>/dev/null || true)"
    expected="$(readlink -f -- "$file")"
    if [[ "$actual" != "$expected" ]]; then
        printf '  [skip]    %s (points elsewhere: %s)\n' "$link" "$actual"
        skipped=$((skipped + 1))
        continue
    fi

    if [[ "$APPLY" == true ]]; then
        rm -- "$link"
        printf '  [removed] %s\n' "$link"
    else
        printf '  [would remove] %s\n' "$link"
    fi
    removed=$((removed + 1))
done < <(command find "$PACKAGE_DIR" -type f -print0)

# In apply mode, prune any directories that became empty.
if [[ "$APPLY" == true ]]; then
    while IFS= read -r -d '' dir; do
        [[ "$dir" == "$TARGET" ]] && continue
        while [[ "$dir" != "$TARGET" && "$dir" != "/" ]]; do
            if rmdir -- "$dir" 2>/dev/null; then
                printf '  [removed] %s (empty directory)\n' "$dir"
                dir="$(dirname -- "$dir")"
            else
                break
            fi
        done
    done < <(command find "$PACKAGE_DIR" -type d -print0 | sort -rz)
fi

printf '\n'
if [[ "$APPLY" == true ]]; then
    printf 'Removed %s symlink(s); skipped %s.\n' "$removed" "$skipped"
else
    printf 'Would remove %s symlink(s); skipped %s.\n' "$removed" "$skipped"
    printf 'Run again with --apply to actually remove them.\n'
fi
