#!/usr/bin/env bash
set -Eeuo pipefail

REPO_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TEMP_DIR="$(mktemp -d)"
trap 'rm -rf -- "$TEMP_DIR"' EXIT

TEST_REPO="$TEMP_DIR/dotfiles"
MOCK_BIN="$TEMP_DIR/bin"

mkdir -p "$TEST_REPO" "$MOCK_BIN"
cp -a "$REPO_DIR/scripts" "$REPO_DIR/packages" "$TEST_REPO/"

# Mock package commands so tests cannot install anything.
# Record invocations to verify invalid manifests fail before package checks.
PACMAN_LOG="$TEMP_DIR/pacman.log"
export PACMAN_LOG

cat > "$MOCK_BIN/pacman" <<'MOCK'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "$PACMAN_LOG"
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

# Assert that an invalid manifest is rejected before pacman is queried.
assert_rejected_before_pacman() {
    local test_description="$1"
    local pass_message="$2"
    local fail_message="$3"

    : > "$PACMAN_LOG"
    run_test "$test_description" 1

    if [[ ! -s "$PACMAN_LOG" ]]; then
        printf 'PASS: %s\n' "$pass_message"
    else
        printf 'FAIL: %s\n' "$fail_message"
        cat "$PACMAN_LOG"
        exit 1
    fi
}

printf '%s\n' '--- Isolated manifest validation ---'

# Empty manifest must fail before checking package installation.
: > "$TEST_REPO/packages/arch/required.txt"
run_test "Reject empty manifest" 1

# Invalid package entries must fail before package checks.
printf 'zsh\nbad package name\n' > "$TEST_REPO/packages/arch/required.txt"
run_test "Reject invalid package entry" 1

# Invalid manifests must be rejected before querying pacman.
: > "$TEST_REPO/packages/arch/required.txt"
assert_rejected_before_pacman \
    "Empty manifest does not query pacman" \
    "Empty manifest rejected before package checks" \
    "Empty manifest queried pacman"

printf 'zsh\nbad package name\n' > "$TEST_REPO/packages/arch/required.txt"
assert_rejected_before_pacman \
    "Invalid entry does not query pacman" \
    "Invalid entry rejected before package checks" \
    "Invalid entry queried pacman"

# Internal whitespace must not be silently removed from package names.
printf 'zsh\nbad package name\ngit\n' > "$TEST_REPO/packages/arch/required.txt"
assert_rejected_before_pacman \
    "Reject package name containing internal whitespace" \
    "Internal whitespace rejected before package checks" \
    "Internal whitespace reached package checks"

# Invalid characters must be rejected before package checks.
printf 'zsh\nbad/package\ngit\n' > "$TEST_REPO/packages/arch/required.txt"
assert_rejected_before_pacman \
    "Reject package name containing slash" \
    "Invalid character rejected before package checks" \
    "Invalid character reached package checks"

# A valid manifest should reach the package-checking stage and
# complete in dry-run mode even when every package is missing.
printf 'zsh\ngit\nstow\n' > "$TEST_REPO/packages/arch/required.txt"
run_test "Dry run handles missing packages without installing" 0
if [[ -s "$PACMAN_LOG" ]]; then
    printf '%s\n' 'PASS: Valid manifest reached package checks'
else
    printf '%s\\n' 'FAIL: Valid manifest did not query pacman'
    exit 1
fi

# Leading/trailing whitespace, blank lines, and comments are allowed.
printf '  zsh  \n\n# A comment\ngit # inline comment\n  stow\n' \
    > "$TEST_REPO/packages/arch/required.txt"
run_test "Accept whitespace, blank lines, and comments" 0

# Duplicate package names must be rejected before querying pacman.
printf 'zsh\ngit\nzsh\nstow\n' > "$TEST_REPO/packages/arch/required.txt"
assert_rejected_before_pacman \
    "Reject duplicate package entries" \
    "Duplicate entries rejected before package checks" \
    "Duplicate entries queried pacman"

# Comments and whitespace alone must not count as package entries.
printf '   \n\n# No packages here\n    \n# Another comment\n' \
    > "$TEST_REPO/packages/arch/required.txt"
run_test "Reject comments and whitespace only" 1

printf '%s\n' 'Manifest tests completed.'
