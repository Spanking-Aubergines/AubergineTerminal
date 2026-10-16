# Testing

All checks are run by a single entry point:

~~~sh
./tests/run-all.sh
~~~

It runs, in order:

1. `shellcheck` on every shell script
2. `tests/test-installer.sh` — installer argument validation
3. `tests/test-manifest.sh` — manifest parsing and package checks
4. `bash -n` and `zsh -n` syntax checks
5. `git diff --check` for whitespace errors

## Test layout

- `tests/test-installer.sh`
  Exercises `scripts/install.sh` argument parsing: help flags, conflicting
  modes, missing `--stow` values, invalid Stow package names, and detection
  of already-managed configuration.

- `tests/test-manifest.sh`
  Exercises manifest parsing and package-check behaviour for both supported
  distributions. It runs the installer inside a temporary copy of the repo
  with mocked `pacman`, `dpkg-query`, and `apt-get` binaries so tests cannot
  touch the host system.

## Conventions

- Each test asserts both the exit status and, where relevant, that the
  mocked package manager was or was not invoked.
- Tests never install, remove, or modify packages on the host.
- Temporary state lives under `mktemp -d` and is removed on exit.
- Tests are distribution-aware: the same script covers Arch Linux and Debian
  paths.

## Adding a test

1. Put the new case in the appropriate existing test file unless it is a new
   category.
2. Assert on exit code and on side effects (log files, symlinks, output).
3. Run `./tests/run-all.sh` — the pre-commit hook runs it automatically.
