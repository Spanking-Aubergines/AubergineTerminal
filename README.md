# dotfiles

Portable dotfiles for Arch Linux and Debian, with a dry-run-first installer.

## What this is

A small, opinionated dotfiles repository managed with GNU Stow. Zsh is the
interactive shell; Bash is used for scripts. The installer never makes
changes without being asked.

## Requirements

- Arch Linux or Debian
- Bash (bootstrap)
- `git`, `zsh`, `stow` (see `docs/dependencies.md`)

## Quick start

~~~sh
git clone <this-repo> ~/.dotfiles
cd ~/.dotfiles
./scripts/install.sh
./scripts/install.sh --install
./scripts/install.sh --stow zsh
./scripts/install.sh --stow zsh --apply
./scripts/install.sh --set-shell
~~~

Run `./scripts/install.sh --help` for all flags.

## Layout

- `scripts/install.sh` — installer (dry-run by default)
- `packages/<distro>/required.txt` — desired packages per distribution
- `zsh/.zshrc` — shell configuration (deployed via Stow)
- `docs/decisions.md` — project decisions
- `docs/dependencies.md` — dependency inventory
- `tests/` — installer and manifest regression tests

## Tests

Run everything with one command:

~~~sh
./tests/run-all.sh
~~~

Or run the individual checks:

~~~sh
./tests/test-installer.sh
./tests/test-manifest.sh
shellcheck scripts/install.sh tests/*.sh
~~~

## Development

Install the repo's Git hooks once after cloning:

~~~sh
./scripts/install-hooks.sh
~~~

The pre-commit hook runs `./tests/run-all.sh` before each commit.

## Safety

- Dry-run is the default.
- Installation, Stow deployment, and login-shell changes are separate steps.
- The installer asks before installing packages and before applying Stow.
- The login shell is only changed with explicit confirmation.
- Existing unmanaged config files are never overwritten.
