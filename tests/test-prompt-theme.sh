#!/usr/bin/env bash
set -Eeuo pipefail

REPO_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPT="$REPO_DIR/scripts/prompt-theme.sh"
TMP_DIR="$(mktemp -d)"

cleanup() {
    rm -rf -- "$TMP_DIR"
}
trap cleanup EXIT

export XDG_CONFIG_HOME="$TMP_DIR/config"
export PATH="$TMP_DIR/bin:$PATH"
mkdir -p "$XDG_CONFIG_HOME" "$TMP_DIR/bin"

cat > "$TMP_DIR/bin/oh-my-posh" <<'STUB'
#!/usr/bin/env bash
case "${1:-}" in
    print)
        # print primary --config FILE
        shift
        [[ "${1:-}" == "primary" ]] || exit 2
        shift
        [[ "${1:-}" == "--config" ]] || exit 2
        cfg="${2:-}"
        [[ -n "$cfg" && -r "$cfg" ]]
        ;;
    *)
        exit 2
        ;;
esac
STUB
chmod +x "$TMP_DIR/bin/oh-my-posh"

fail() {
    printf 'FAIL: %s\n' "$*" >&2
    exit 1
}

pass() {
    printf 'PASS: %s\n' "$*"
}

printf '%s\n' '--- Prompt theme selector ---'

# 1. Selecting a known theme by name saves it.
if ! "$SCRIPT" voight >/dev/null 2>&1; then
    fail "selecting voight by name"
fi
saved="$(<"$XDG_CONFIG_HOME/ohmyposh-theme")"
[[ "$saved" == "voight" ]] || fail "saved theme should be voight, got: $saved"
pass "selects theme by name and saves selection"

# 2. Selecting an unknown theme fails.
if "$SCRIPT" does-not-exist >/dev/null 2>&1; then
    fail "unknown theme should fail"
fi
pass "rejects unknown theme name"

# 3. Interactive selection by number.
printf '1\n' | "$SCRIPT" >/dev/null 2>&1 || fail "interactive selection failed"
saved="$(<"$XDG_CONFIG_HOME/ohmyposh-theme")"
[[ -n "$saved" ]] || fail "interactive selection did not save a theme"
pass "interactive selection saves a theme"

# 4. Blank input cancels without changing the saved theme.
previous="$saved"
printf '\n' | "$SCRIPT" >/dev/null 2>&1 || fail "blank input should exit cleanly"
saved="$(<"$XDG_CONFIG_HOME/ohmyposh-theme")"
[[ "$saved" == "$previous" ]] || fail "blank input should not change selection"
pass "blank input cancels without changing selection"

# 5. Invalid number fails.
if printf '99\n' | "$SCRIPT" >/dev/null 2>&1; then
    fail "out-of-range selection should fail"
fi
pass "rejects out-of-range selection"

printf '\nAll prompt theme tests passed.\n'
