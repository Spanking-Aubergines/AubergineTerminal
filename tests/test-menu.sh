#!/usr/bin/env bash
set -Eeuo pipefail

REPO_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
MENU="$REPO_DIR/scripts/menu.sh"

passed=0
failed=0

pass() {
    printf 'PASS: %s\n' "$1"
    passed=$((passed + 1))
}

fail() {
    printf 'FAIL: %s\n' "$1"
    failed=$((failed + 1))
}

printf '%s\n' '--- Menu regression tests ---'

if bash -n "$MENU"; then
    pass "Menu Bash syntax"
else
    fail "Menu Bash syntax"
fi

if [[ -x "$MENU" ]]; then
    pass "Menu is executable"
else
    fail "Menu is executable"
fi

if output="$(printf 'q\n' | NO_COLOR=1 "$MENU" 2>&1)"; then
    if grep -q 'SYSTEM DASHBOARD' <<< "$output" &&
       grep -q 'ACTIONS' <<< "$output" &&
       grep -q 'AUBERGINE TERMINAL' <<< "$output"; then
        pass "Menu renders header, status and actions"
    else
        fail "Menu renders header, status and actions"
        printf '%s\n' "$output"
    fi

    if grep -q 'GNU Stow' <<< "$output" &&
       grep -q 'Package mgr' <<< "$output" &&
       grep -q 'Manifest' <<< "$output" &&
       grep -q 'Git branch' <<< "$output" &&
       grep -q 'Stow packages' <<< "$output"; then
        pass "System status includes required checks"
    else
        fail "System status includes required checks"
        printf '%s\n' "$output"
    fi

    if grep -q 'Diagnostics are read-only; no packages or configurations were changed.' <<< "$output"; then
        pass "Status panel explains its read-only behaviour"
    else
        fail "Status panel explains its read-only behaviour"
    fi

    if grep -q $'\033' <<< "$output"; then
        fail "NO_COLOR disables ANSI colour output"
    else
        pass "NO_COLOR disables ANSI colour output"
    fi

    if grep -q 'Bye\.' <<< "$output"; then
        pass "Quit option exits cleanly"
    else
        fail "Quit option exits cleanly"
    fi
else
    fail "Menu exits successfully when quitting"
fi

if output="$(printf 'invalid\n\nq\n' | NO_COLOR=1 "$MENU" 2>&1)"; then
    if grep -q 'Unknown choice: invalid' <<< "$output"; then
        pass "Invalid choice is reported without exiting"
    else
        fail "Invalid choice is reported without exiting"
        printf '%s\n' "$output"
    fi
else
    fail "Menu handles invalid choice"
fi

printf '\nPassed: %s\nFailed: %s\n' "$passed" "$failed"

if ((failed > 0)); then
    exit 1
fi

printf '%s\n' 'All menu tests passed.'
