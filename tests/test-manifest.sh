#!/usr/bin/env bash
set -Eeuo pipefail

REPO_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TEMP_DIR="$(mktemp -d)"
trap 'rm -rf -- "$TEMP_DIR"' EXIT

TEST_REPO="$TEMP_DIR/dotfiles"
MOCK_BIN="$TEMP_DIR/bin"

mkdir -p "$TEST_REPO" "$MOCK_BIN"
cp -a "$REPO_DIR/scripts" "$REPO_DIR/packages" "$TEST_REPO/"

# Mock package commands so the tests cannot install anything.
cat > "$MOCK_BIN/pacman" <<'MOCK'
#!/usr/bin/env bash
if [[ "${1:-}" == "-Q" ]]; then
    exit 1
fi
printf 'Unexpected pacman invocation: %s\n' "$*" >&2
exit 99
MOCK

chmod +x "$MOCK_BIN/pacman"

run_test() {
    local description="$1"
    local expected="$2"
    local output
    local actual

    shift 2

    if output="$(PATH="$MOCK_BIN:$PATH" "$TEST_REPO/scripts/install.sh" "$@" 2>&1)"; then
        actual=0
    else
        actual=$?
    fi

    if [[ "$actual" -eq "$expected" ]]; then
        printf 'PASS: %s\n' "$description"
    else
        printf 'FAIL: %s (expected %s, got %s)\n' \
            "$description" "$expected" "$actual"
        printf '%s\n' "$output"
        return 1
    fi
}

printf '%s\n' '--- Isolated manifest validation ---'

# Empty manifest must fail before checking package installation.
: > "$TEST_REPO/packages/arch/required.txt"
run_test "Reject empty manifest" 1

# Invalid package entries must fail before package checks.
printf 'zsh\nbad package name\n' > "$TEST_REPO/packages/arch/required.txt"
run_test "Reject invalid package entry" 1

# A valid manifest should reach the package-checking stage and
# complete in dry-run mode even when every package is missing.
printf 'zsh\ngit\nstow\n' > "$TEST_REPO/packages/arch/required.txt"
run_test "Dry run handles missing packages without installing" 0

# Leading/trailing whitespace, blank lines, and comments are allowed.
printf '  zsh  \n\n# A comment\ngit # inline comment\n  stow\n' \
    > "$TEST_REPO/packages/arch/required.txt"
run_test "Accept whitespace, blank lines, and comments" 0

# Duplicate package names: record current behavior before changing the parser.
printf 'zsh\ngit\nzsh\nstow\n' > "$TEST_REPO/packages/arch/required.txt"
run_test "Reject duplicate package entries" 1

printf '%s\n' 'Manifest tests completed.'
