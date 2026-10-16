#!/usr/bin/env bash
set -Eeuo pipefail

REPO_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
HOOK_SRC="$REPO_DIR/scripts/hooks/pre-commit"
HOOK_DST="$REPO_DIR/.git/hooks/pre-commit"

if [[ ! -d "$REPO_DIR/.git/hooks" ]]; then
    printf 'Not a git repository: %s\n' "$REPO_DIR" >&2
    exit 1
fi

if [[ ! -f "$HOOK_SRC" ]]; then
    printf 'Hook source not found: %s\n' "$HOOK_SRC" >&2
    exit 1
fi

chmod +x "$HOOK_SRC"
ln -sf ../../scripts/hooks/pre-commit "$HOOK_DST"
printf 'Installed pre-commit hook.\n'
