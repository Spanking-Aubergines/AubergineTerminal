#!/usr/bin/env bash
set -Eeuo pipefail

REPO_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TEMP_DIR="$(mktemp -d)"
trap 'rm -rf -- "$TEMP_DIR"' EXIT

FAKE_HOME="$TEMP_DIR/home"
mkdir -p "$FAKE_HOME"

passed=0
failed=0

check() {
    local desc="$1" ok="$2"
    if [[ "$ok" == true ]]; then
        printf 'PASS: %s\n' "$desc"
        passed=$((passed + 1))
    else
        printf 'FAIL: %s\n' "$desc"
        failed=$((failed + 1))
    fi
}

printf '%s\n' '--- Unstow script ---'

# 1. Missing package argument.
if ! HOME="$FAKE_HOME" "$REPO_DIR/scripts/unstow.sh" >/dev/null 2>&1; then
    check "Rejects missing package" true
else
    check "Rejects missing package" false
fi

# 2. Invalid package name.
if ! HOME="$FAKE_HOME" "$REPO_DIR/scripts/unstow.sh" '../etc' >/dev/null 2>&1; then
    check "Rejects invalid package name" true
else
    check "Rejects invalid package name" false
fi

# 3. Nonexistent package.
if ! HOME="$FAKE_HOME" "$REPO_DIR/scripts/unstow.sh" does-not-exist >/dev/null 2>&1; then
    check "Rejects nonexistent package" true
else
    check "Rejects nonexistent package" false
fi

# 4. Dry-run does not modify the filesystem.
HOME="$FAKE_HOME" stow --dir="$REPO_DIR" --target="$FAKE_HOME" kitty 2>/dev/null
link_path="$FAKE_HOME/.config/kitty/kitty.conf"
if [[ -L "$FAKE_HOME/.config" ]]; then
    link_path="$FAKE_HOME/.config"
fi
HOME="$FAKE_HOME" "$REPO_DIR/scripts/unstow.sh" kitty >/dev/null 2>&1 </dev/null || true
if [[ -L "$link_path" ]]; then
    check "Dry-run leaves symlinks in place" true
else
    check "Dry-run leaves symlinks in place" false
fi

# 5. Apply removes symlinks and reports counts.
if output="$(HOME="$FAKE_HOME" "$REPO_DIR/scripts/unstow.sh" kitty --apply 2>&1 </dev/null)"; then
    if [[ ! -L "$FAKE_HOME/.config/kitty/kitty.conf" && ! -L "$FAKE_HOME/.config/kitty/current-theme.conf" ]]; then
        check "Apply removes symlinks" true
    else
        check "Apply removes symlinks" false
    fi
else
    check "Apply removes symlinks" false
    printf '%s\n' "$output"
fi

# 6. Skips files that are not symlinks. Use a fresh HOME so nothing can
#    write through a folded symlink into the repository.
FAKE_HOME2="$TEMP_DIR/home2"
mkdir -p "$FAKE_HOME2/.config/btop"
printf 'not a symlink\n' > "$FAKE_HOME2/.config/btop/btop.conf"
if output="$(HOME="$FAKE_HOME2" "$REPO_DIR/scripts/unstow.sh" btop 2>&1 </dev/null)"; then
    if [[ -f "$FAKE_HOME2/.config/btop/btop.conf" && ! -L "$FAKE_HOME2/.config/btop/btop.conf" ]]; then
        check "Leaves non-symlink files alone" true
    else
        check "Leaves non-symlink files alone" false
    fi
else
    check "Leaves non-symlink files alone" false
fi

# Guard: the test must never have written into the repository.
if [[ -e "$REPO_DIR/btop/.config/btop/not-a-symlink" || -e "$REPO_DIR/kitty/.config/btop" ]]; then
    check "Test did not leak files into the repository" false
else
    check "Test did not leak files into the repository" true
fi

printf '\n%s\n' '--- Summary ---'
printf 'Passed: %s\n' "$passed"
printf 'Failed: %s\n' "$failed"

if ((failed > 0 )); then
    exit 1
fi
