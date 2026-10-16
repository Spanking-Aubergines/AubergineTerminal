#!/usr/bin/env bash
set -Eeuo pipefail

REPO_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TEMP_DIR="$(mktemp -d)"
trap 'rm -rf -- "$TEMP_DIR"' EXIT

FUNCTIONS_FILE="$REPO_DIR/zsh/functions.zsh"
ZSH_BIN="$(command -v zsh)"
MOCK_BIN="$TEMP_DIR/bin"
mkdir -p "$MOCK_BIN"

PASS_COUNT=0
FAIL_COUNT=0

pass() {
    printf 'PASS: %s\n' "$1"
    PASS_COUNT=$((PASS_COUNT + 1))
}

fail() {
    printf 'FAIL: %s\n' "$1"
    FAIL_COUNT=$((FAIL_COUNT + 1))
}

printf '%s\n' '--- Zsh function tests ---'

# mkcd: create and enter a directory.
if output="$(zsh -c '
    source "$1"
    mkcd "$2"
    [[ "$PWD" == "$2" ]]
' zsh-test "$FUNCTIONS_FILE" "$TEMP_DIR/created/nested" 2>&1)" &&
   [[ -d "$TEMP_DIR/created/nested" ]]; then
    pass "mkcd creates and enters a nested directory"
else
    fail "mkcd creates and enters a nested directory"
    printf '%s\n' "$output"
fi

if output="$(zsh -c 'source "$1"; mkcd' zsh-test "$FUNCTIONS_FILE" 2>&1)"; then
    fail "mkcd rejects a missing argument"
else
    status=$?
    if [[ "$status" -eq 1 && "$output" == *"usage: mkcd DIR"* ]]; then
        pass "mkcd rejects a missing argument"
    else
        fail "mkcd rejects a missing argument"
        printf 'status=%s output=%s\n' "$status" "$output"
    fi
fi

# extract: reject missing files and unknown extensions.
if output="$(zsh -c 'source "$1"; extract' zsh-test "$FUNCTIONS_FILE" 2>&1)"; then
    fail "extract rejects a missing argument"
else
    status=$?
    if [[ "$status" -eq 1 && "$output" == *"usage: extract FILE"* ]]; then
        pass "extract rejects a missing argument"
    else
        fail "extract rejects a missing argument"
        printf 'status=%s output=%s\n' "$status" "$output"
    fi
fi

printf 'not an archive\n' > "$TEMP_DIR/unknown.data"
if output="$(zsh -c 'source "$1"; extract "$2"' zsh-test "$FUNCTIONS_FILE" "$TEMP_DIR/unknown.data" 2>&1)"; then
    fail "extract rejects an unknown archive extension"
else
    status=$?
    if [[ "$status" -eq 1 && "$output" == *"Unknown archive type"* ]]; then
        pass "extract rejects an unknown archive extension"
    else
        fail "extract rejects an unknown archive extension"
        printf 'status=%s output=%s\n' "$status" "$output"
    fi
fi

# Create and extract a real tar.gz archive in the temporary directory.
mkdir -p "$TEMP_DIR/archive-source" "$TEMP_DIR/archive-output"
printf 'archive test content\n' > "$TEMP_DIR/archive-source/example.txt"
tar -czf "$TEMP_DIR/example.tar.gz" -C "$TEMP_DIR/archive-source" example.txt

if output="$(cd "$TEMP_DIR/archive-output" &&
    zsh -c 'source "$1"; extract "$2"' zsh-test "$FUNCTIONS_FILE" "$TEMP_DIR/example.tar.gz" 2>&1)" &&
   [[ "$(cat "$TEMP_DIR/archive-output/example.txt")" == "archive test content" ]]; then
    pass "extract correctly extracts a tar.gz archive"
else
    fail "extract correctly extracts a tar.gz archive"
    printf '%s\n' "${output:-No output}"
fi

# Simulate an unavailable extraction utility without changing the host.
mkdir -p "$TEMP_DIR/no-unzip"
: > "$TEMP_DIR/unknown.zip"
cat > "$TEMP_DIR/no-unzip/tar" <<'MOCK'
#!/usr/bin/env bash
exit 0
MOCK
chmod +x "$TEMP_DIR/no-unzip/tar"

# The single-quoted program must reach Zsh unchanged; its positional
# parameters are intentionally expanded by Zsh, not by Bash.
# shellcheck disable=SC2016
if output="$(PATH="$TEMP_DIR/no-unzip" "$ZSH_BIN" -c '
    source "$1"
    extract "$2"
' zsh-test "$FUNCTIONS_FILE" "$TEMP_DIR/unknown.zip" 2>&1)"; then
    fail "extract reports a missing extraction utility"
else
    status=$?
    if [[ "$status" -eq 127 && "$output" == *"Required extraction tool not found: unzip"* ]]; then
        pass "extract reports a missing extraction utility"
    else
        fail "extract reports a missing extraction utility"
        printf 'status=%s output=%s\n' "$status" "$output"
    fi
fi

# Mock ps to test CPU/memory sorting output and output limits.
cat > "$MOCK_BIN/ps" <<'MOCK'
#!/usr/bin/env bash
# head intentionally closes the pipe early; suppress expected broken-pipe errors.
exec 2>/dev/null
case "$*" in
    *%cpu*)
        printf 'PID PPID CMD %%CPU\n'
        for pid in {101..111}; do
            printf '%s 1 cpu-process-%s %s.0\n' "$pid" "$pid" "$pid"
        done
        ;;
    *%mem*)
        printf 'PID PPID CMD %%MEM\n'
        for pid in {201..211}; do
            printf '%s 1 mem-process-%s %s.0\n' "$pid" "$pid" "$pid"
        done
        ;;
    *)
        printf 'Unexpected ps arguments: %s\n' "$*" >&2
        exit 99
        ;;
esac
MOCK
chmod +x "$MOCK_BIN/ps"

# The single-quoted program is intentionally passed to Zsh unchanged.
# shellcheck disable=SC2016
if output="$(PATH="$MOCK_BIN:$PATH" "$ZSH_BIN" -c '
    source "$1"
    topcpu 2
' zsh-test "$FUNCTIONS_FILE" 2>&1)" &&
   [[ "$(printf '%s\n' "$output" | wc -l)" -eq 2 &&
      "$output" == *"cpu-process-101"* &&
      "$output" != *"cpu-process-102"* ]]; then
    pass "topcpu respects a custom output limit"
else
    fail "topcpu respects a custom output limit"
    printf '%s\n' "${output:-No output}"
fi

# The single-quoted program is intentionally passed to Zsh unchanged.
# shellcheck disable=SC2016
if output="$(PATH="$MOCK_BIN:$PATH" "$ZSH_BIN" -c '
    source "$1"
    topmem 2
' zsh-test "$FUNCTIONS_FILE" 2>&1)" &&
   [[ "$(printf '%s\n' "$output" | wc -l)" -eq 2 &&
      "$output" == *"mem-process-201"* &&
      "$output" != *"mem-process-202"* ]]; then
    pass "topmem respects a custom output limit"
else
    fail "topmem respects a custom output limit"
    printf '%s\n' "${output:-No output}"
fi

# The single-quoted program is intentionally passed to Zsh unchanged.
# shellcheck disable=SC2016
if output="$(PATH="$MOCK_BIN:$PATH" "$ZSH_BIN" -c '
    source "$1"
    topcpu
' zsh-test "$FUNCTIONS_FILE" 2>&1)" &&
   [[ "$(printf '%s\n' "$output" | wc -l)" -eq 10 ]]; then
    pass "topcpu defaults to 10 lines"
else
    fail "topcpu defaults to 10 lines"
    printf '%s\n' "${output:-No output}"
fi

# The single-quoted program is intentionally passed to Zsh unchanged.
# shellcheck disable=SC2016
if output="$(PATH="$MOCK_BIN:$PATH" "$ZSH_BIN" -c '
    source "$1"
    topmem
' zsh-test "$FUNCTIONS_FILE" 2>&1)" &&
   [[ "$(printf '%s\n' "$output" | wc -l)" -eq 10 ]]; then
    pass "topmem defaults to 10 lines"
else
    fail "topmem defaults to 10 lines"
    printf '%s\n' "${output:-No output}"
fi

# Mock ss to test port output and invalid arguments deterministically.
cat > "$MOCK_BIN/ss" <<'MOCK'
#!/usr/bin/env bash
printf '%s\n' \
    'Netid State  Local Address:Port Peer Address:Port Process' \
    'tcp   LISTEN 0.0.0.0:22       0.0.0.0:*' \
    'tcp   LISTEN 0.0.0.0:8080     0.0.0.0:*'
MOCK
chmod +x "$MOCK_BIN/ss"

if output="$(PATH="$MOCK_BIN:$PATH" zsh -c '
    source "$1"
    port 22
' zsh-test "$FUNCTIONS_FILE" 2>&1)" &&
   [[ "$output" == *"0.0.0.0:22"* ]]; then
    pass "port displays a matching listening port"
else
    fail "port displays a matching listening port"
    printf '%s\n' "${output:-No output}"
fi

for invalid_port in abc 0 65536; do
    if output="$(PATH="$MOCK_BIN:$PATH" zsh -c '
        source "$1"
        port "$2"
    ' zsh-test "$FUNCTIONS_FILE" "$invalid_port" 2>&1)"; then
        fail "port rejects invalid input: $invalid_port"
    else
        status=$?
        if [[ "$status" -eq 2 && "$output" == *"usage: port PORT (1-65535)"* ]]; then
            pass "port rejects invalid input: $invalid_port"
        else
            fail "port rejects invalid input: $invalid_port"
            printf 'status=%s output=%s\n' "$status" "$output"
        fi
    fi
done

printf '\nPassed: %s\nFailed: %s\n' "$PASS_COUNT" "$FAIL_COUNT"
(( FAIL_COUNT == 0 ))
