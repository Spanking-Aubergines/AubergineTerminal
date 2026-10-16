#!/usr/bin/env bash
set -Eeuo pipefail

REPO_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPT="$REPO_DIR/scripts/starship-themes.sh"
TMP_DIR="$(mktemp -d)"

cleanup() {
    rm -rf -- "$TMP_DIR"
}
trap cleanup EXIT

export XDG_CONFIG_HOME="$TMP_DIR/config"
export PATH="$TMP_DIR/bin:$PATH"
mkdir -p "$XDG_CONFIG_HOME" "$TMP_DIR/bin"

cat > "$TMP_DIR/bin/starship" <<'STUB'
#!/usr/bin/env bash
case "${1:-}" in
    explain)
        [[ -n "${STARSHIP_CONFIG:-}" && -r "$STARSHIP_CONFIG" ]]
        ;;
    prompt)
        printf '%%{\033[1;32m%%}PREVIEW%%{\033[0m%%}\n'
        ;;
    *)
        exit 2
        ;;
esac
STUB
chmod +x "$TMP_DIR/bin/starship"

fail() {
    printf 'FAIL: %s\n' "$*" >&2
    exit 1
}

pass() {
    printf 'PASS: %s\n' "$*"
}

output="$("$SCRIPT" list)"
[[ "$output" == *"voight.toml"* ]] || fail "list should include voight.toml"
[[ "$output" == *"minimal.toml"* ]] || fail "list should include minimal.toml"
pass "lists available themes"

output="$("$SCRIPT" current)"
[[ "$output" == *"voight (default)"* ]] || fail "default theme should be voight"
pass "reports the default theme"

output="$("$SCRIPT" preview cyberpunk-green)"
[[ "$output" == *"PREVIEW"* ]] || fail "preview should display prompt output"
[[ "$output" != *'%{'* && "$output" != *'%}'* ]] ||
    fail "preview should remove Zsh prompt wrapper markers"
[[ ! -e "$XDG_CONFIG_HOME/starship-theme" ]] ||
    fail "preview must not create a saved selection"
pass "preview renders output without saving a selection"

"$SCRIPT" apply minimal >/dev/null
saved="$(<"$XDG_CONFIG_HOME/starship-theme")"
[[ "$saved" == "minimal" ]] || fail "apply should save minimal"
pass "applies a valid theme"

if "$SCRIPT" apply '../invalid' >/dev/null 2>&1; then
    fail "invalid theme name should be rejected"
fi
saved="$(<"$XDG_CONFIG_HOME/starship-theme")"
[[ "$saved" == "minimal" ]] || fail "invalid theme must not change the selection"
pass "rejects invalid theme names without changing selection"

printf '\nAll Starship theme tests passed.\n'
