#!/usr/bin/env bash
set -Eeuo pipefail

REPO_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TEMP_DIR="$(mktemp -d)"
trap 'rm -rf -- "$TEMP_DIR"' EXIT

FAKE_HOME="$TEMP_DIR/home"
CLONE_DIR="$TEMP_DIR/clone"
CLONE_DIR2="$TEMP_DIR/clone2"
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

printf '%s\n' '--- Bootstrap script ---'

# 1. Refuses to run without a repo URL.
if ! "$REPO_DIR/scripts/bootstrap.sh" >/dev/null 2>&1; then
    check "Refuses without repo URL" true
else
    check "Refuses without repo URL" false
fi

# 2. Refuses to overwrite an existing target directory.
mkdir -p "$CLONE_DIR"
if ! "$REPO_DIR/scripts/bootstrap.sh" -r "file://$REPO_DIR" -d "$CLONE_DIR" >/dev/null 2>&1; then
    check "Refuses existing target" true
else
    check "Refuses existing target" false
fi
rm -rf -- "$CLONE_DIR"

# 3. Clones the repository and runs the installer in dry-run mode.
if output="$(HOME="$FAKE_HOME" "$REPO_DIR/scripts/bootstrap.sh" \
        -r "file://$REPO_DIR" -d "$CLONE_DIR" 2>&1)"; then
    check "Clones and runs installer" true
else
    check "Clones and runs installer" false
    printf '%s\n' "$output"
fi

# 4. Clone contains the expected files.
if [[ -f "$CLONE_DIR/scripts/install.sh" && -f "$CLONE_DIR/README.md" ]]; then
    check "Cloned repository has expected files" true
else
    check "Cloned repository has expected files" false
fi

# 5. Fresh HOME starts without any dotfiles.
if [[ ! -e "$FAKE_HOME/.zshrc" && ! -e "$FAKE_HOME/.config/ohmyposh/themes" ]]; then
    check "Fresh HOME starts empty" true
else
    check "Fresh HOME starts empty" false
fi

# 6. Bootstrap with --stow zsh --apply deploys files into a fresh HOME.
if printf 'y\n' | HOME="$FAKE_HOME" "$REPO_DIR/scripts/bootstrap.sh" \
        -r "file://$REPO_DIR" -d "$CLONE_DIR2" -- --stow zsh --apply >/dev/null 2>&1; then
    check "Bootstrap deploys zsh package" true
else
    check "Bootstrap deploys zsh package" false
fi

# 7. The deployed files are symlinks into the clone.
if [[ -L "$FAKE_HOME/.zshrc" ]] && \
   [[ "$(readlink -f -- "$FAKE_HOME/.zshrc")" == "$CLONE_DIR2/zsh/.zshrc" ]]; then
    check "Fresh HOME got .zshrc symlink into clone" true
else
    check "Fresh HOME got .zshrc symlink into clone" false
fi

if [[ -f "$FAKE_HOME/.config/ohmyposh/themes/voight.omp.json" ]] && \
   [[ "$(readlink -f -- "$FAKE_HOME/.config/ohmyposh/themes/voight.omp.json")" == "$CLONE_DIR2/zsh/.config/ohmyposh/themes/voight.omp.json" ]]; then
    check "Fresh HOME got voight.omp.json reachable in clone" true
else
    check "Fresh HOME got voight.omp.json reachable in clone" false
fi

printf '\n%s\n' '--- Summary ---'
printf 'Passed: %s\n' "$passed"
printf 'Failed: %s\n' "$failed"

if ((failed > 0)); then
    exit 1
fi
