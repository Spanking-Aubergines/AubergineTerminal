#!/usr/bin/env bash
set -Eeuo pipefail

REPO_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_DIR"

printf '%s\n' '--- ShellCheck ---'
shellcheck scripts/install.sh tests/test-installer.sh tests/test-manifest.sh tests/run-all.sh

printf '\n%s\n' '--- Installer regression tests ---'
./tests/test-installer.sh

printf '\n%s\n' '--- Manifest tests ---'
./tests/test-manifest.sh

printf '\n%s\n' '--- Syntax checks ---'
bash -n scripts/install.sh tests/test-installer.sh tests/test-manifest.sh
zsh -n zsh/.zshrc

printf '\n%s\n' '--- Whitespace check ---'
git diff --check

printf '\n%s\n' 'All checks passed.'
