#!/usr/bin/env bash
set -Eeuo pipefail

REPO_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
INSTALLER="$REPO_DIR/scripts/install.sh"

passed=0
failed=0

run_test() {
    local description="$1"
    local expected="$2"
    shift 2

    local output
    local actual

    if output="$("$INSTALLER" "$@" 2>&1)"; then
        actual=0
    else
        actual=$?
    fi

    if [[ "$actual" -eq "$expected" ]]; then
        printf 'PASS: %s\n' "$description"
        passed=$((passed + 1))
    else
        printf 'FAIL: %s (expected %s, got %s)\n' \
            "$description" "$expected" "$actual"
        printf '%s\n' "$output"
        failed=$((failed + 1))
    fi
}

printf '%s\n' '--- Installer syntax ---'
if bash -n "$INSTALLER"; then
    printf '%s\n' 'PASS: Bash syntax'
    passed=$((passed + 1))
else
    printf '%s\n' 'FAIL: Bash syntax'
    failed=$((failed + 1))
fi

printf '\n%s\n' '--- Zsh configuration syntax ---'
if command -v zsh >/dev/null 2>&1; then
    if zsh -n "$REPO_DIR/zsh/.zshrc"; then
        printf '%s\n' 'PASS: Zsh configuration syntax'
        passed=$((passed + 1))
    else
        printf '%s\n' 'FAIL: Zsh configuration syntax'
        failed=$((failed + 1))
    fi
else
    printf '%s\n' 'SKIP: Zsh is not installed'
fi

printf '\n%s\n' '--- Help and argument validation ---'

run_test "Help option" 0 --help
run_test "Short help option" 0 -h
run_test "Reject conflicting modes" 2 --install --dry-run
run_test "Reject conflicting modes in reverse order" 2 --dry-run --install
run_test "Reject repeated Stow option" 2 --stow zsh --stow zsh
run_test "Reject missing Stow package" 2 --stow
run_test "Reject shell change combined with dry run" 2 --set-shell --dry-run
run_test "Reject shell change combined with Stow" 2 --stow zsh --set-shell
run_test "Reject apply without Stow" 2 --apply
run_test "Reject install combined with Stow" 2 --stow zsh --install
run_test "Reject repeated apply option" 2 --stow zsh --apply --apply
run_test "Reject repeated shell option" 2 --set-shell --set-shell
run_test "Reject unknown option" 2 --not-a-real-option
run_test "Reject invalid Stow package name" 2 --stow '../zsh'
run_test "Reject nonexistent Stow package" 1 --stow package-that-does-not-exist
run_test "Recognise already-managed Zsh configuration" 0 --stow zsh

# Regression: when .zshrc is already managed, the installer must still
# invoke stow so newly added files in the package get deployed.
TMP_HOME="$(mktemp -d)"
MOCK_BIN="$(mktemp -d)"
trap 'rm -rf -- "$TMP_HOME" "$MOCK_BIN"' RETURN

ln -s "$REPO_DIR/zsh/.zshrc" "$TMP_HOME/.zshrc"

cat > "$MOCK_BIN/stow" <<'MOCK'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "$STOW_LOG"
exit 0
MOCK
chmod +x "$MOCK_BIN/stow"

STOW_LOG="$MOCK_BIN/stow.log"
: > "$STOW_LOG"

if printf 'y\n' | HOME="$TMP_HOME" STOW_LOG="$STOW_LOG" PATH="$MOCK_BIN:$PATH" \
    "$INSTALLER" --stow zsh --apply >/dev/null 2>&1; then
    if [[ -s "$STOW_LOG" ]]; then
        printf '%s\n' 'PASS: Stow invoked even when .zshrc already managed'
        passed=$((passed + 1))
    else
        printf '%s\n' 'FAIL: Stow not invoked when .zshrc already managed'
        failed=$((failed + 1))
    fi
else
    printf '%s\n' 'FAIL: Installer exited non-zero when .zshrc already managed'
    failed=$((failed + 1))
fi

rm -rf -- "$TMP_HOME" "$MOCK_BIN"
trap - RETURN

printf '\n%s\n' '--- Summary ---'
printf 'Passed: %s\n' "$passed"
printf 'Failed: %s\n' "$failed"

if ((failed > 0)); then
    exit 1
fi

printf '%s\n' 'All tests passed.'
