#!/usr/bin/env bash
set -Eeuo pipefail

REPO_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_DIR"

printf '%s\n' '--- ShellCheck ---'
shellcheck scripts/install.sh scripts/install-hooks.sh scripts/bootstrap.sh scripts/hooks/pre-commit tests/test-installer.sh tests/test-manifest.sh tests/test-zsh-functions.sh tests/run-all.sh

printf '\n%s\n' '--- Installer regression tests ---'
./tests/test-installer.sh

printf '\n%s\n' '--- Manifest tests ---'
./tests/test-manifest.sh

./tests/test-zsh-functions.sh

printf '\n%s\n' '--- Syntax checks ---'
bash -n scripts/install.sh tests/test-installer.sh tests/test-manifest.sh tests/test-zsh-functions.sh
zsh -n zsh/.zshrc zsh/aliases.zsh zsh/functions.zsh

printf '\n%s\n' '--- Whitespace check ---'
git diff --check

printf '\n%s\n' 'All checks passed.'
